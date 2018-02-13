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

import ruamel.yaml

SITEFILE = "/repository/ansible/site.yml"
DSTPATH = "/ansible"

with open(SITEFILE, "r") as fp:
    site = ruamel.yaml.load(fp, ruamel.yaml.RoundTripLoader)

SUPPORTED_ROLES = [
    "aodh",
    "ceilometer",
    "chrony",
    "cinder",
    "cloudkitty",
    "elasticsearch",
    "glance",
    "gnocchi",
    "grafana",
    "haproxy",
    "heat",
    "horizon",
    "iscsi",
    "keystone",
    "kibana",
    "magnum",
    "manila",
    "mariadb",
    "memcached",
    "mistral",
    "multipathd",
    "neutron",
    "nova",
    "octavia",
    "openvswitch",
    "ovs-dpdk",
    "panko",
    "rabbitmq",
    "rally",
    "redis",
    "searchlight",
    "skydive",
    "tempest",
    "vitrage",
    "watcher"
]

for play in site:
    print("CHECKING PLAY %s" % play)
    if play["name"].startswith("Apply role") and not play["name"].endswith("prechecks"):
        name = play["name"][11:]
        print("FOUND ROLE %s" % name)

        if name in SUPPORTED_ROLES:
            print("SUPPORTED ROLE %s" % name)
            play["gather_facts"] = "no"
            dump = ruamel.yaml.dump([play], Dumper=ruamel.yaml.RoundTripDumper, indent=4, block_seq_indent=2)
            with open(os.path.join(DSTPATH, "kolla-%s.yml" % name), "w+") as fp:
                fp.write("---\n")
                for line in dump.splitlines():
                    fp.write(line[2:])
                    fp.write("\n")
