#!/usr/bin/env python

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os

import jinja2
import yaml

# get environment parameters

OPENSTACK_VERSION = os.environ.get("OPENSTACK_VERSION", "queens")
OSISM_VERSION = os.environ.get("OSISM_VERSION", "latest")

# load versions files from release repository

with open("release/%s/base.yml" % OSISM_VERSION, "rb") as fp:
    versions = yaml.load(fp)

with open("release/%s/openstack-%s.yml" % (OSISM_VERSION, OPENSTACK_VERSION), "rb") as fp:
    openstack_versions = yaml.load(fp)

# prepare jinja2 environment

loader = jinja2.FileSystemLoader(searchpath="templates/")
environment = jinja2.Environment(loader=loader)

# render requirements.txt

template = environment.get_template("requirements.txt.j2")
result = template.render({
  'ansible_version': openstack_versions['ansible_version'],
  'osism_projects': versions['osism_projects']
})
with open("files/requirements.txt", "w+") as fp:
    fp.write(result)
