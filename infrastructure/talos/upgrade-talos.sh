#!/usr/bin/env bash
. $(dirname "$0")/common.sh

echo -e "${BLUE}This will upgrade Talos on each node in the cluster.${NC}"

check_rook_health
check_postgres_health

get_nodes

for key in "${!workers[@]}";
do
  upgrade_talos_on_node "$key" "${workers[$key]}"
done

for key in "${!controlplanes[@]}";
do
  upgrade_talos_on_node "$key" "${controlplanes[$key]}"
done

echo "----------------------------------------------------------------"
echo -e "${GREEN}Upgrade complete!${NC}"
