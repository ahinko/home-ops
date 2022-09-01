#!/bin/bash

. $(dirname "$0")/common.sh

# Get name of rook ceph tools pod
ROOK_CEPH_TOOLS_POD=$(kubectl get pod -l app=rook-ceph-tools -n rook-ceph -o jsonpath="{.items[0].metadata.name}")

# make sure rook ceph is healthy
HEALTH_CHECK=$(kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -it ceph status | grep "health:")

if [[ $HEALTH_CHECK != *"HEALTH_OK"* ]]; then
  die "Make sure Rook/Ceph cluster is healthy since we determine by checking that when cycling through nodes"
fi

STRING=$(yq '.nodes | map(.ipAddress) ' < $(dirname "$0")/talconfig.yaml)

IPS=(${STRING//-/})

for IP in "${IPS[@]}"
do
  if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "-----------------------------------"
    echo "Upgrading Talos on IP $IP"

    talosctl upgrade --stage --preserve --force -n $IP --image ghcr.io/siderolabs/installer:v1.2.0

    echo "Sleeping and waiting for node to become ready"
    sleep 10
    kubectl wait --for=condition=Ready nodes --all --timeout=600s

    HEALTH=false
    while [ "$HEALTH" == false ]
    do
      echo "Rook/Ceph not healthy, waiting 60s before checking again."

      # Sleep 60 seconds just to give Rook/Ceph time to get healthy
      sleep 60

      echo "Checking again..."

      # Get name of rook ceph tools pod
      ROOK_CEPH_TOOLS_POD=$(kubectl get pod -l app=rook-ceph-tools -n rook-ceph -o jsonpath="{.items[0].metadata.name}")

      # make sure rook ceph is healthy
      HEALTH_CHECK=$(kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -it ceph status | grep "health:")

      if [[ $HEALTH_CHECK == *"HEALTH_OK"* ]]; then
        HEALTH=true
      fi
    done

    echo "Rook/Ceph is healthy, let's move on to the next node"
  fi
done
