#!/bin/sh
CONTAINER=haproxy

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
  -v "/mnt/data/haproxy/:/usr/local/etc/haproxy/" \
  docker.io/library/haproxy:2.5.7-alpine # renovate
