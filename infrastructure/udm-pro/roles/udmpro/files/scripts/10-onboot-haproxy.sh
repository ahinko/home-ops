#!/bin/sh

## configuration variables:
VLAN=5
# This is the IP address of the container. You may want to set it to match
# your own network structure such as 192.168.5.3 or similar.
IPV4_IP="192.168.5.20"
# As above, this should match the gateway of the VLAN for the container
# network as above which is usually the .1/24 range of the IPV4_IP
IPV4_GW="192.168.5.1/24"
# Set which DNS server should be used instead of /etc/resolv.conf in the container.
# Without this some IPV6 addresses would be added and HAProxy would fail to start.
DNS="192.168.5.1"

# container name
CONTAINER=haproxy

if ! test -f /opt/cni/bin/macvlan; then
    echo "Error: CNI plugins not found. You can install it with the following command:" >&2
    echo "       /mnt/data/on_boot.d/05-install-cni-plugins.sh"
    exit 1
fi

# set VLAN bridge promiscuous
ip link set "br${VLAN}" promisc on

# create macvlan bridge and add IPv4 IP
ip link add "br${VLAN}.mac" link "br${VLAN}" type macvlan mode bridge
ip addr add "${IPV4_GW}" dev "br${VLAN}.mac" noprefixroute

# (optional) add IPv6 IP to VLAN bridge macvlan bridge
if [ -n "${IPV6_GW}" ]; then
  ip -6 addr add "${IPV6_GW}" dev "br${VLAN}.mac" noprefixroute
fi

# set macvlan bridge promiscuous and bring it up
ip link set "br${VLAN}.mac" promisc on
ip link set "br${VLAN}.mac" up

# add IPv4 route to DNS container
ip route add "${IPV4_IP}/32" dev "br${VLAN}.mac"

# (optional) add IPv6 route to DNS container
if [ -n "${IPV6_IP}" ]; then
  ip -6 route add "${IPV6_IP}/128" dev "br${VLAN}.mac"
fi

# Starts a haproxy container that is deleted after it is stopped.
# All configs stored in /mnt/data/haproxy
if podman container exists "$CONTAINER"; then
  podman pull $CONTAINER
  podman stop $CONTAINER
  podman rm $CONTAINER
fi

podman run -d --network haproxy --restart always \
  --name "$CONTAINER" \
  --hostname haproxy \
  --dns $DNS \
  -v "/mnt/data/haproxy/:/usr/local/etc/haproxy/" \
  docker.io/library/haproxy:2.6.0-alpine # renovate
