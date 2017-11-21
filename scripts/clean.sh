#!/usr/bin/env bash
set -x

docker system prune -a -f

# NOTE(berendt): not using git -d here to avoid removal of .vangrant and roles
rm -rf .venv release
git clean -f -x
git checkout .
