#!/bin/bash

. $(dirname "$0")/common.sh

# Get name of rook ceph tools pod
ROOK_CEPH_TOOLS_POD=$(kubectl get pod -l app=rook-ceph-tools -n rook-ceph -o jsonpath="{.items[0].metadata.name}")

# make sure rook ceph is healthy
HEALTH_CHECK=$(kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -- ceph status | grep "health:")

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

    talosctl upgrade --preserve --wait -n $IP --image ghcr.io/siderolabs/installer:v1.3.3

    # HACK: helios will hold up everything (because rook-ceph + controlplane) for up to 15 minutes until the taint has been removed.
    if [[ $IP == "192.168.20.21" ]]; then
      kubectl create job --from=cronjob/tainter -n kube-system tainter-temp
    fi

    HEALTH=false
    while [ "$HEALTH" == false ]
    do
      echo "Checking if Rook/Ceph is healthy."

      # Get name of rook ceph tools pod
      ROOK_CEPH_TOOLS_POD=$(kubectl get pod -l app=rook-ceph-tools -n rook-ceph -o jsonpath="{.items[0].metadata.name}")

      # make sure rook ceph is healthy
      HEALTH_CHECK=$(kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -- ceph status | grep "health:")

      if [[ $HEALTH_CHECK == *"HEALTH_OK"* ]]; then
        HEALTH=true
      else
        echo "Rook/Ceph not healthy, waiting 60s before checking again."
        sleep 60

        # Archive any crash messages since those will be holding up everything since the health will be false until those
        # messages has been archived
        kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -- ceph crash archive-all
      fi
    done

    echo "Rook/Ceph is healthy, let's move on to the next node"
  fi
done
