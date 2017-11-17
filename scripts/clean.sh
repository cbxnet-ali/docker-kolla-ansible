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

docker rmi "$TAG"
docker rmi "$TAG-$(git rev-parse --short HEAD)"

docker system prune -a -f

# NOTE(berendt): not using git -d here to avoid removal of .vangrant and roles
rm -rf .venv release
git clean -f -x
git checkout .
