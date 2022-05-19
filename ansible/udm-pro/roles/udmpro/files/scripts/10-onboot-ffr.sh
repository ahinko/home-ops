#!/usr/bin/env sh

DEBUG=${DEBUG:--d}
CONTAINER_NAME="frr"

if podman container exists ${CONTAINER_NAME}; then
  podman start ${CONTAINER_NAME}
else
  podman run --mount="type=bind,source=/mnt/data/$CONTAINER_NAME,destination=/etc/frr/" \
            --name "$CONTAINER_NAME" \
            --network=host \
            --privileged \
            --restart always \
            $DEBUG \
            docker.io/frrouting/frr:v8.1.0
fi