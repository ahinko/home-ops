#!/bin/bash

. $(dirname "$0")/common.sh

set -o allexport; source $REPO_ROOT/.env; set +o allexport

# Verify that needed tools are installed
need kubectl
need flux
need talhelper
need talosctl
need sops
need ansible-playbook

# Verify that we have all environment variables that we need
need_variable GITHUB_USER
need_variable GITHUB_TOKEN

# Make sure we have a talconfig
if [ ! -f "$(dirname "$0")/talconfig.yaml" ]; then
    die "talconfig.yaml does not exist."
fi

get_setup_ip
get_vip

if [ ! -f "$(dirname "$0")/talenv.sops.yaml" ]; then
  # Generate talhelper secrets
  talhelper gensecret -c $(dirname "$0")/talconfig.yaml --patch-configfile > $(dirname "$0")/talenv.sops.yaml

  # Encrypt the secret with SOPS:
  sops -e -i $(dirname "$0")/talenv.sops.yaml
fi

echo "Temporarily changing cluster endpoint to one of the control planes ($SETUP_IP). Needed since VIP wont be up in time."
gsed -i "s/endpoint: [a-z:.\/0-9]*/endpoint: https:\/\/$SETUP_IP:6443/g" $(dirname "$0")/talconfig.yaml

# Run talhelper genconfig and the output files will be in ./clusterconfig by default.
talhelper genconfig -c $(dirname "$0")/talconfig.yaml -o $(dirname "$0")/clusterconfig -e $(dirname "$0")/talenv.sops.yaml

talosctl config merge $(dirname "$0")/clusterconfig/talosconfig

CONTROLPLANE_PROVISIONED=false

# Loop through nodes and find control planes
for FILE in "$(dirname "$0")/clusterconfig"/*
do
  if [[ $FILE =~ .*metal.*.yaml$ ]]; then
    TYPE=$(yq '.machine.type' < $FILE)

    if [[ $TYPE == "controlplane" ]]; then
      HOSTNAME=$(yq '.machine.network.hostname' < $FILE)
      IP=$(yq '.machine.network.interfaces[0].addresses[0] ' < $FILE)
      IP=${IP%???}

      # Make sure we can talk with the node
      MAINTENANCE_MODE=$(talosctl version -n $IP --insecure 2>&1)
      if [[ $MAINTENANCE_MODE != *"maintenance"* ]]; then
        echo "ERROR: $IP ($HOSTNAME) is not reachable or does not have Talos running. Ignoring.."
        continue
      fi

      # Take the generated talosconfig files and provision control plane nodes
      talosctl apply-config --insecure -n $IP -f $(dirname "$0")/clusterconfig/metal-$HOSTNAME.yaml

      CONTROLPLANE_PROVISIONED=true
    fi
  fi
done

if [[ $CONTROLPLANE_PROVISIONED == false ]]; then
  die "Could not install Talos on any of the control planes. Exiting.."
fi

echo "Wait for Talos OS to become ready"
while ! talosctl version -n $SETUP_IP >/dev/null 2>&1; do sleep 3; done

# Bootstrap etcd
echo "Bootstrap etcd"
talosctl bootstrap -n $SETUP_IP

# Wait for control planes to get ready
echo "Waiting for the first control plane to get up and running"
while ! curl -k "https://${SETUP_IP}:6443/version?timeout=30s" >/dev/null 2>&1; do sleep 3; done

# Apply Cilium quick install
kubectl apply -f $(dirname "$0")/integrations/cilium-quick-install/quick-install.yaml

# Wait for VIP to get ready
echo "Waiting for VIP to get up and running"
while ! curl -k "https://${VIP}:6443/version?timeout=30s" >/dev/null 2>&1; do sleep 3; done

echo "Set cluster endpoint to VIP ($VIP) in talconfig"
gsed -i "s/endpoint: [a-z:.\/0-9]*/endpoint: https:\/\/$VIP:6443/g" $(dirname "$0")/talconfig.yaml

echo "Generating updated configs for each node with new cluster endpoint (using VIP)"
talhelper genconfig -c $(dirname "$0")/talconfig.yaml -o $(dirname "$0")/clusterconfig -e $(dirname "$0")/talenv.sops.yaml

# Loop through nodes
for FILE in "$(dirname "$0")/clusterconfig"/*
do
  if [[ $FILE =~ .*metal.*.yaml$ ]]; then
    TYPE=$(yq '.machine.type' < $FILE)
    HOSTNAME=$(yq '.machine.network.hostname' < $FILE)
    IP=$(yq '.machine.network.interfaces[0].addresses[0] ' < $FILE)

    if [[ $TYPE == "worker" ]]; then
      # Make sure we can talk with the node
      talosctl version -n $IP >/dev/null 2>&1 || echo "ERROR: $IP ($HOSTNAME) is not reachable or does not have Talos running. Ignoring.." && continue

      # Take the generated talosconfig files and provision control plane nodes
      talosctl apply-config --insecure -n $IP -f $(dirname "$0")/clusterconfig/metal-$HOSTNAME.yaml

    elif [[ $TYPE == "controlplane" ]]; then
      # Re-apply config with updated endpoint (using VIP)
      talosctl apply-config -n $IP -f $(dirname "$0")/clusterconfig/metal-$HOSTNAME.yaml

      # NOTE: this is a hack tailor made for my needs. I have one control plane node that is x64 based and 2 Raspberry Pi 4.
      # I want to allow scheduling on the x64 node but not on the RPI:s. So by looking at the installation disk I can determine
      # which node is a x64 based on if it is an NVMe (RPi uses SSD). This might not apply to everyones environment so modify this if needed.
      INSTALL_DISK=$(yq '.machine.install.disk' < $FILE)

      if [[ $INSTALL_DISK == *"nvme0n1"* ]]; then
        #echo "Untaint control plane node ($HOSTNAME) that run x64"
        kubectl taint node $HOSTNAME node-role.kubernetes.io/master:NoSchedule-
      fi
    fi
  fi
done

# Get kubeconfig
mkdir -p ~/.kube/configs
talosctl kubeconfig ~/.kube/configs/metal -n $SETUP_IP
kubectl config rename-context admin@metal metal

# switch context
echo "Switch kubectl context to 'metal'"
kubectx metal

echo "Waiting for nodes to become ready"
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Flux (namespace + sops secret + deploy flux)
# Create flux-system namespace
echo "Creating flux-system namespace"
kubectl create namespace flux-system

# Create a secret in the cluster containing the decryption key for SOPS
echo "Import SOPS key to cluster"
cat $REPO_ROOT/homelab.agekey | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin

# Bootstrap Flux
echo "Bootstrapping Flux"
kubectl apply --server-side --kustomize ./bootstrap/flux
kubectl apply --server-side --kustomize $REPO_ROOT/kubernetes/flux/vars/
kubectl apply --server-side --kustomize $REPO_ROOT/kubernetes/flux/config/

# Wait for flux to deploy
echo "Waiting for Flux to become ready"
kubectl -n flux-system wait --for=condition=ready pod -l app=helm-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=kustomize-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=source-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=notification-controller

echo "Deploy resources to cluster"
kubectl apply --server-side --kustomize $REPO_ROOT/flux/config
