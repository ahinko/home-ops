#!/bin/bash

# Read variables from environment file
set -o allexport; source .env; set +o allexport

# Verify that we have the needed environment variables
if [ -z "$SIDERO_ENDPOINT" ] ; then
    echo "Environment variable SIDERO_ENDPOINT not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi
if [ -z "$METAL_CLUSTER_VIP" ] ; then
    echo "Environment variable METAL_CLUSTER_VIP not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi
if [ -z "$VLAN_NAMESERVER" ] ; then
    echo "Environment variable VLAN_NAMESERVER not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi
if [ -z "$VLAN_GATEWAY" ] ; then
    echo "Environment variable VLAN_GATEWAY not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi
if [ -z "$GITHUB_USER" ] ; then
    echo "Environment variable GITHUB_USER not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi
if [ -z "$GITHUB_TOKEN" ] ; then
    echo "Environment variable GITHUB_TOKEN not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi

# Install Talos
echo "Installing Talos on ${SIDERO_ENDPOINT}"
talosctl gen config --config-patch='[{"op": "add", "path": "/machine/network/nameservers", "value": [ "'${VLAN_NAMESERVER}'" ] },{"op": "add", "path": "/machine/network/interfaces", "value": [ {"interface": "eth0", "dhcp": false, "routes": [ {"network": "0.0.0.0/0", "gateway": "'${VLAN_GATEWAY}'"} ], "addresses": [ "'${SIDERO_ENDPOINT}'/24" ] }]},{"op": "add", "path": "/machine/network/hostname", "value": "sidero"},{"op": "add", "path": "/cluster/allowSchedulingOnMasters", "value": true},{"op": "replace", "path": "/machine/install/disk", "value": "/dev/sda"}]' sidero https://${SIDERO_ENDPOINT}:6443/
talosctl apply-config --insecure -n ${SIDERO_ENDPOINT} -f controlplane.yaml
talosctl config merge talosconfig
talosctl config endpoints ${SIDERO_ENDPOINT}
talosctl config nodes ${SIDERO_ENDPOINT}
talosctl version

# Remove temp files
rm controlplane.yaml worker.yaml talosconfig

# Bootstrap etcd
talosctl bootstrap

# Download kubeconfig
mkdir -p ~/.kube/configs
talosctl kubeconfig ~/.kube/configs/sidero
kubectl config rename-context admin@sidero ${KUBECTL_CONTEXT_SIDERO}

echo "Switch kubectl context"
kubectx ${KUBECTL_CONTEXT_SIDERO}

# Export values used during cluster init
export SIDERO_CONTROLLER_MANAGER_HOST_NETWORK=true
export SIDERO_CONTROLLER_MANAGER_DEPLOYMENT_STRATEGY=Recreate
export SIDERO_CONTROLLER_MANAGER_API_ENDPOINT=${SIDERO_ENDPOINT}
echo "Installing Sidero on ${SIDERO_ENDPOINT}"
clusterctl init -i sidero -b talos -c talos --kubeconfig ~/.kube/configs/sidero

echo "Waiting for Sidero to be ready"
kubectl -n sidero-system wait --for=condition=ready pod -l app=sidero
kubectl -n sidero-system wait --for=condition=ready environment default

# Verify that TFTP server is up and running
status_code=$(curl --write-out %{http_code} --silent --output /dev/null -I http://${SIDERO_ENDPOINT}:8081/tftp/ipxe.efi)

echo -n "Verifying that the TFTP server is running: "
if [[ "$status_code" -ne 200 ]] ; then
  echo "not running"
else
  echo "all good!"
fi

# Create flux-system namespace
echo "Creating flux-system namespace"
kubectl create namespace flux-system

echo "Import SOPS key to cluster"
# Create a secret in the cluster containing the decryption key for SOPS
cat homelab.agekey | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin

echo "Bootstrapping Flux"
# Bootstrap Flux
flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=homelab \
    --branch=main \
    --path=./kubernetes/management/base/ \
    --personal

# Wait for flux to deploy
kubectl -n flux-system wait --for=condition=ready pod -l app=helm-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=kustomize-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=source-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=notification-controller
