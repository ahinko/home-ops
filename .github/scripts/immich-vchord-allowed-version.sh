#!/bin/bash

# renovate: datasource=docker depName=ghcr.io/immich-app/immich-server
version=v2.5.2

# Get file from immich repo that includes VectorChord version range
SOURCE_CONSTANTS=$(curl -s https://raw.githubusercontent.com/immich-app/immich/$version/server/src/constants.ts)

# Extract the upper bound constraint (e.g., "<0.6" or "<=0.6") from VECTORCHORD_VERSION_RANGE
ALLOWED_VERSION=$(echo "$SOURCE_CONSTANTS" | sed -n "s/.*VECTORCHORD_VERSION_RANGE = '>=[0-9.]* \(<[=]*[0-9.]*\)'.*/\1/p")

# Update renovate config for vchord-scratch
sed -i "s/allowedVersions: \"<[^\"]*\", \/\/ immich/allowedVersions: \"${ALLOWED_VERSION}\", \/\/ immich/" .renovate/allowedVersions.json5
