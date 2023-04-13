#!/bin/bash

NODE=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.ipAddress)' < $(dirname "$0")/talconfig.yaml)
NODE=${NODE:2}

echo "Taking a snapshot of etcd that can be used in disaster recovery"
talosctl -n $NODE etcd snapshot etcd.backup

echo "Upgrading Kubernetes"
talosctl -n $NODE upgrade-k8s --to v1.26.4
