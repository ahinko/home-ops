#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

die() { echo "ERROR: $*" 1>&2 ; exit 1; }

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required. Use 'task tools:install'"
}

need_variable() {
  if [ -z "${!1}" ] ; then
      die "Environment variable $1 not set. Either export it or create an .env file in the root of the repo!"
  fi
}

get_setup_ip() {
  PARSED_SETUP_IP=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.ipAddress)' < $(dirname "$0")/talconfig.yaml)
  SETUP_IP=${PARSED_SETUP_IP#??}
}

get_vip() {
  PARSED_VIP=$(yq '.nodes | map(select(.controlPlane == true)) | pick([0]) | map(.networkInterfaces[0].vip.ip)' < $(dirname "$0")/talconfig.yaml)
  VIP=${PARSED_VIP#??}
}
