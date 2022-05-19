#!/usr/bin/env sh

DEBUG=${DEBUG:--d}
CONTAINER_NAME="rsyncd"
SSH_PORT="2202"
RSYNC_PORT="873"

if podman container exists ${CONTAINER_NAME}; then
  podman start ${CONTAINER_NAME}
else
  podman run --mount="type=bind,source=/mnt/,destination=/data/,ro" \
           --mount="type=bind,source=/root/.ssh,destination=/root/.ssh/,ro" \
            --name "$CONTAINER_NAME" \
            --restart always \
            -p $SSH_PORT:22 \
            -p $RSYNC_PORT:873 \
            $DEBUG \
            docker.io/mabunixda/rsyncd
fi
