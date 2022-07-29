#!/bin/bash

. $(dirname "$0")/common.sh

set -o allexport; source $REPO_ROOT/.env; set +o allexport

need talhelper

# Make sure we have a talconfig
if [ ! -f "$(dirname "$0")/talconfig.yaml" ]; then
    die "talconfig.yaml does not exist."
fi

get_setup_ip
get_vip

echo "Temporarily changing cluster endpoint to one of the control planes ($SETUP_IP)."
gsed -i "s/endpoint: [a-z:.\/0-9]*/endpoint: https:\/\/$SETUP_IP:6443/g" $(dirname "$0")/talconfig.yaml

# Run talhelper genconfig and the output files will be in ./clusterconfig by default.
talhelper genconfig -c $(dirname "$0")/talconfig.yaml -o $(dirname "$0")/clusterconfig -e $(dirname "$0")/talenv.sops.yaml

# Loop through nodes and find control planes
for FILE in "$(dirname "$0")/clusterconfig"/*
do
  if [[ $FILE =~ .*metal.*.yaml$ ]]; then
    TYPE=$(yq '.machine.type' < $FILE)

    if [[ $TYPE == "controlplane" ]]; then
      HOSTNAME=$(yq '.machine.network.hostname' < $FILE)
      IP=$(yq '.machine.network.interfaces[0].addresses[0] ' < $FILE)
      IP=${IP%???}

      echo "Apply config on $IP"
      # Take the generated talosconfig files and provision control plane nodes
      #talosctl apply-config --insecure -n $IP -f $(dirname "$0")/clusterconfig/metal-$HOSTNAME.yaml
    fi
  fi
done

echo "Waiting for VIP to get up and running"
while ! curl -k "https://${VIP}:6443/version?timeout=30s" >/dev/null 2>&1; do sleep 3; done

echo "VIP is up and running, restoring config"

gsed -i "s/endpoint: [a-z:.\/0-9]*/endpoint: https:\/\/$VIP:6443/g" $(dirname "$0")/talconfig.yaml
talhelper genconfig -c $(dirname "$0")/talconfig.yaml -o $(dirname "$0")/clusterconfig -e $(dirname "$0")/talenv.sops.yaml

# Loop through nodes and find control planes
for FILE in "$(dirname "$0")/clusterconfig"/*
do
  if [[ $FILE =~ .*metal.*.yaml$ ]]; then
    TYPE=$(yq '.machine.type' < $FILE)

    if [[ $TYPE == "controlplane" ]]; then
      HOSTNAME=$(yq '.machine.network.hostname' < $FILE)
      IP=$(yq '.machine.network.interfaces[0].addresses[0] ' < $FILE)
      IP=${IP%???}

      echo "Apply config on $IP"
      # Take the generated talosconfig files and provision control plane nodes
      #talosctl apply-config --insecure -n $IP -f $(dirname "$0")/clusterconfig/metal-$HOSTNAME.yaml
    fi
  fi
done
