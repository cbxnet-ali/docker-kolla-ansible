#!/usr/bin/env bash
set -x

# Available environment variables
#
# CLEAN
# OPENSTACK_VERSION
# OSISM_VERSION
# PUSH

export OPENSTACK_VERSION=${OPENSTACK_VERSION:-pike}
export OSISM_VERSION=${OSISM_VERSION:-latest}

PUSH=${PUSH:-true}
CLEAN=${CLEAN:-true}

bash scripts/build.sh

if [[ $PUSH == "true" ]]; then
    bash scripts/push.sh
fi

if [[ $CLEAN == "true" ]]; then
    bash scripts/clean.sh
fi
