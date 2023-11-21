#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

die() { echo "ERROR: $*" 1>&2 ; exit 1; }

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required. Use 'task tools:install'"
}

need_variable() {
  if [ -z "${!1}" ] ; then
      die "Environment variable $1 not set. Either export it or create an .env file in the root of the repo!"
  fi
}

get_setup_ip() {
  PARSED_SETUP_IP=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.ipAddress)' < $(dirname "$0")/talconfig.yaml)
  SETUP_IP=${PARSED_SETUP_IP#??}
}

get_vip() {
  PARSED_VIP=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.networkInterfaces[0].vip.ip)' < $(dirname "$0")/talconfig.yaml)
  VIP=${PARSED_VIP#??}
}

check_rook_health() {
  HEALTH=false
  while [ "$HEALTH" == false ]
  do
    echo "Checking if Rook/Ceph cluster is healthy."

    if kubectl get -n rook-ceph cephcluster rook-ceph | grep -q 'HEALTH_OK'; then
      HEALTH=true
    else
      echo -e "${RED}Rook/Ceph cluster not healthy, waiting 60s before checking again.${NC}"
      sleep 60

      # Archive any crash messages since those will be holding up everything since the health will be false until those
      # messages has been archived
      ROOK_CEPH_TOOLS_POD=$(kubectl get pod -l app=rook-ceph-tools -n rook-ceph -o jsonpath="{.items[0].metadata.name}")
      kubectl exec -n rook-ceph $ROOK_CEPH_TOOLS_POD -c rook-ceph-tools -- ceph crash archive-all
    fi
  done

  echo -e "${GREEN}Rook/Ceph is healthy, let's move on${NC}"
}

check_postgres_health() {

  HEALTH=false

  while [ "$HEALTH" == false ]
  do
    echo "Checking if Postgres cluster is healthy."

    if kubectl get clusters.postgresql.cnpg.io -n databases postgres16 | grep -q 'Cluster in healthy state'; then
      HEALTH=true
    else
      echo -e "${RED}Postgres cluster not healthy, waiting 60s before checking again.${NC}"
      sleep 60
    fi
  done

  echo -e "${GREEN}Postgres cluster is healthy, let's move on${NC}"
}

declare -A controlplanes
declare -A workers
get_nodes() {
  config=$(yq e -o=j -I=0 '.nodes[]' $(dirname "$0")/talconfig.yaml)

  while IFS=\= read node; do
      IS_CONTROL_PLANE=$(echo "$node" | yq e '.controlPlane')

      if [[ $IS_CONTROL_PLANE == "true" ]]; then
        controlplanes[$(echo "$node" | yq e '.hostname')]="$(echo "$node" | yq e '.ipAddress')"
      else
        workers[$(echo "$node" | yq e '.hostname')]="$(echo "$node" | yq e '.ipAddress')"
      fi
  done <<< "$config"
}

upgrade_talos_on_node() {
  NODENAME=$1
  IP=$2

  echo "----------------------------------------------------------------"
  echo -e "${BLUE}Upgrading Talos on node ${NC}${NODENAME}${BLUE} with IP ${NC}${IP}. ${BLUE}This will reboot the node${NC}."

  talosctl apply-config -n ${IP} -f $(dirname "$0")/clusterconfig/metal-${NODENAME}.yaml

  # HACK: zeus or poseidon will hold up everything (because rook-ceph + controlplane) for up to 15 minutes until the taint has been removed.
  if [[ $NODENAME == "zeus" || $NODENAME == "poseidon" ]]; then
    kubectl delete job -n kube-system tainter-temp
    kubectl create job --from=cronjob/tainter -n kube-system tainter-temp
  fi

  # Give the node some time to recover and start up pods
  sleep 60

  check_rook_health
  check_postgres_health
}
