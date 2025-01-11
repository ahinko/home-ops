#!/bin/bash

REPO_PATH=$(dirname "$(dirname "$(readlink -f "$0")")")

DOCKER_PATH="${REPO_PATH}/docker"

# Do a git pull to get all the latest changes
git -C $REPO_PATH pull

# Use hostname to determine which subfolder to use.
DOCKER_PATH="${DOCKER_PATH}/$HOSTNAME"

# Loop through each folder in the docker folder and call docker-compose to pull any updated
# images as well as build and deamonize.
for d in $DOCKER_PATH/*/ ; do
    cd $d
    /usr/bin/docker compose -f docker-compose.yaml pull
    /usr/bin/docker compose -f docker-compose.yaml up -d --build
done
