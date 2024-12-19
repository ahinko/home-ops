#!/bin/bash

# Find current Talos version .taskfiles/sidero.yaml
TALOS_VERSION="$(sed -n 's/.*talosVersion: \([v0-9.]*\)/\1/p' infrastructure/talos/talconfig.yaml)"

# Get file from Talos repo that includes default Kubernetes version
SOURCE_CONSTANTS=$(curl -s https://raw.githubusercontent.com/siderolabs/talos/$TALOS_VERSION/pkg/machinery/constants/constants.go)

# Find kubernetes version
TALOS_K8S_VERSION=$(expr "$SOURCE_CONSTANTS" : '.*DefaultKubernetesVersion = "\([0-9.]*\)"')

# Concat to only include major.minor version
ALLOWED_VERSION=$(expr "$TALOS_K8S_VERSION" : '\([0-9.]\{4\}\)')

# Update renovate config
sed -i "s/[0-9.]*\(\", \/\/ Talos dependency\)/${ALLOWED_VERSION}\1/" .github/renovate/allowedVersions.json5
