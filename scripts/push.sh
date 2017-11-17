#!/usr/bin/env bash
set -x

PROJECT=kolla-ansible

# Available environment variables
#
# OPENSTACK_VERSION
# OSISM_VERSION
# REPOSITORY

# Set default values

OPENSTACK_VERSION=${OPENSTACK_VERSION:-ocata}
OSISM_VERSION=${OSISM_VERSION:-latest}
REPOSITORY=${REPOSITORY:-osism/$PROJECT}

TAG=$REPOSITORY:$OPENSTACK_VERSION-$OSISM_VERSION

docker push "$TAG-$(git rev-parse --short HEAD)"

docker tag "$TAG-$(git rev-parse --short HEAD)" "$TAG"
docker push "$TAG"
