#!/bin/bash

# Read variables from environment file
set -o allexport; source .env; set +o allexport

# Verify that we have the needed environment variables
if [ -z "$METAL_CLUSTER_VIP" ] ; then
    echo "Environment variable METAL_CLUSTER_VIP not set. Either export it or create an .env file in the root of the repo!"
    exit 1
fi

kubectx ${KUBECTL_CONTEXT_SIDERO}

# Find the name of the talos config
TALOS_CONFIG=`kubectl get talosconfig -n sidero-system| grep 'metal'|cut -f1 -d ' '`
if [ -z "$TALOS_CONFIG" ] ; then
    echo "Could not parse talosconfig from 'kubectl get talosconfig'. This is needed when getting the talosconfig from the cluster."
    exit 1
fi

# Get talos config and keep it
kubectl get talosconfig -n sidero-system -o yaml ${TALOS_CONFIG} -o jsonpath='{.status.talosConfig}' > metal-talosconfig.yaml
talosctl config merge metal-talosconfig.yaml
talosctl config context admin@metal
talosctl config endpoints ${METAL_CLUSTER_CP_LB}
talosctl config nodes ${METAL_CLUSTER_NODES}

rm metal-talosconfig.yaml

# Bootstrap etcd on one of the nodes
talosctl bootstrap

# Get kube config
mkdir -p ~/.kube/configs
talosctl kubeconfig ~/.kube/configs/metal
kubectl config rename-context admin@metal ${KUBECTL_CONTEXT_METAL}
talosctl config context metal

# switch context
echo "Switch kubectl context"
kubectx ${KUBECTL_CONTEXT_METAL}

# Create flux-system namespace
echo "Creating flux-system namespace"
kubectl create namespace flux-system

# Create a secret in the cluster containing the decryption key for SOPS
echo "Import SOPS key to cluster"
cat homelab.agekey | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin

# Bootstrap Flux
echo "Bootstrapping Flux"
flux bootstrap github \
    --owner=$GITHUB_USER \
    --repository=home-ops \
    --branch=main \
    --path=./kubernetes/metal/base/ \
    --personal

# Wait for flux to deploy
kubectl -n flux-system wait --for=condition=ready pod -l app=helm-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=kustomize-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=source-controller
kubectl -n flux-system wait --for=condition=ready pod -l app=notification-controller
