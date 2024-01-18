#!/usr/bin/env bash
. $(dirname "$0")/common.sh

echo -e "${BLUE}This will upgrade Kubernetes on each Talos node in the cluster.${NC}"

check_rook_health
check_postgres_health

NODE=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.ipAddress)' < $(dirname "$0")/talconfig.yaml)
NODE=${NODE:2}

echo -e "${BLUE}Taking a snapshot of etcd that can be used in disaster recovery${NC}"
talosctl -n $NODE etcd snapshot etcd.backup

talosctl upgrade-k8s -n $NODE --to v1.29.1

echo "----------------------------------------------------------------"
echo -e "${GREEN}Upgrade complete!${NC}"
