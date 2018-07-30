#!/usr/bin/env bash
set -x

PROJECT=kolla-ansible

# Available environment variables
#
# BUILD_OPTS
# OPENSTACK_VERSION
# OSISM_VERSION
# REPOSITORY

# Set default values

BUILD_OPTS=${BUILD_OPTS:-}
OPENSTACK_VERSION=${OPENSTACK_VERSION:-pike}
OSISM_VERSION=${OSISM_VERSION:-latest}
REPOSITORY=${REPOSITORY:-osism/$PROJECT}

HASH_REPOSITORY=$(git rev-parse --short HEAD)

if [[ ! -e release ]]; then
    git clone https://github.com/osism/release
fi

if [[ ! -e release/$OSISM_VERSION/base.yml ]]; then
    echo "release $OSISM_VERSION does not exist"
    exit 1
fi

PROJECT_REPOSITORY=https://github.com/openstack/$PROJECT
PROJECT_VERSION=stable/$OPENSTACK_VERSION
VERSION=$OPENSTACK_VERSION

REPOSITORY_VERSION=$OSISM_VERSION
TAG=$REPOSITORY:$OPENSTACK_VERSION-$OSISM_VERSION

virtualenv .venv
source .venv/bin/activate
pip install -r requirements.txt

python src/render-python-requirements.py
python src/render-versions.py

if [[ $PROJECT == "osism-ansible" ]]; then
    python src/render-ansible-requirements.py
    python src/render-docker-images.py
fi

docker build \
    --squash \
    --build-arg "PROJECT_REPOSITORY=$PROJECT_REPOSITORY" \
    --build-arg "PROJECT_VERSION=$PROJECT_VERSION" \
    --build-arg "REPOSITORY_VERSION=$REPOSITORY_VERSION" \
    --build-arg "VERSION=$VERSION" \
    --label "io.osism.${REPOSITORY#osism/}=$HASH_REPOSITORY" \
    --tag "$TAG-$(git rev-parse --short HEAD)" \
    $BUID_OPTS .
