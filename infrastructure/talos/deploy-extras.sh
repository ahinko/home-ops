#!/bin/bash

kustomize build --enable-helm --load-restrictor LoadRestrictionsNone $(dirname "$0")/integrations/cni/ --output $(dirname "$0")/integrations/cni/cilium.yaml
kubectl apply --server-side -f $(dirname "$0")/integrations/cni/cilium.yaml
rm -rf $(dirname "$0")/integrations/cni/charts

kustomize build --enable-helm --load-restrictor LoadRestrictionsNone $(dirname "$0")/integrations/kubelet-csr-approver/ --output $(dirname "$0")/integrations/kubelet-csr-approver/kubelet-csr-approver.yaml
kubectl apply --server-side -f $(dirname "$0")/integrations/kubelet-csr-approver/kubelet-csr-approver.yaml
rm -rf $(dirname "$0")/integrations/kubelet-csr-approver/charts
