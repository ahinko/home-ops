#!/usr/bin/env bash
. $(dirname "$0")/common.sh

echo -e "${BLUE}This will upgrade Talos on each node in the cluster.${NC}"

check_rook_health
check_postgres_health

config=$(yq e -o=j -I=0 '.nodes[]' $(dirname "$0")/talconfig.yaml)

while IFS=\= read node; do
  NODENAME=$(echo "$node" | yq e '.hostname')
  IP=$(echo "$node" | yq e '.ipAddress')
  IMAGE=$(yq e -o=j -I=0 '.machine.install.image' $(dirname "$0")/clusterconfig/metal-${NODENAME}.yaml | tr -d '"')

  echo "----------------------------------------------------------------"
  echo -e "${BLUE}Upgrading Talos on node ${NC}${NODENAME}${BLUE} with IP ${NC}${IP}"
  echo -e "${BLUE}Using image: ${NC}${IMAGE}"
  echo -e "${BLUE}This will reboot the node${NC}."

  talosctl upgrade --wait --image ${IMAGE} -n ${IP}

  # HACK: zeus or poseidon will hold up everything (because rook-ceph + controlplane) for up to 15 minutes until the taint has been removed.
  if [[ $NODENAME == "zeus" || $NODENAME == "poseidon" ]]; then
    kubectl delete job -n kube-system tainter-temp
    kubectl create job --from=cronjob/tainter -n kube-system tainter-temp
  fi

  # Give the node some time to recover and start up pods
  sleep 60

  check_rook_health
  check_postgres_health

done <<< "$config"

echo "----------------------------------------------------------------"
echo -e "${GREEN}Upgrade complete!${NC}"
