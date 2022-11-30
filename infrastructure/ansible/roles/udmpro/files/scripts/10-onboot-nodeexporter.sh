#!/usr/bin/env sh

DEBUG=${DEBUG:--d}
CONTAINER_NAME="nodexporter"

if podman container exists "$CONTAINER"; then
  podman pull $CONTAINER
  podman stop $CONTAINER
  podman rm $CONTAINER
fi

podman run  --name "$CONTAINER_NAME" \
  --network=host \
  --restart always \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  --path.rootfs=/host \
  $DEBUG \
  quay.io/prometheus/node-exporter:v1.4.1 # renovate
