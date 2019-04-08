#!/bin/bash

# Copyright 2015 The Kubernetes Authors.
#
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

. ./init.sh

inventory=${INVENTORY:-${INVENTORY_DIR}/inventory}
ansible_playbook ${inventory} ${PLAYBOOKS_DIR}/clean.yml "$@"

# Remove binary files
rm -rf ../roles/node/templates/bootstrap.kubeconfig
rm -rf ../roles/node/templates/kube-proxy.kubeconfig
rm -rf ../roles/ssl/package/{cfssl,cfssl-certinfo,cfssljson}
rm -rf ../roles/etcd/package/{etcd,etcdctl}
rm -rf ../roles/flanneld/package/flanneld
rm -rf ../roles/master/package/{kube-apiserver,kube-controller-manager,kubectl,kube-scheduler}
rm -rf ../roles/node/package/{kubelet,kube-proxy}
rm -rf ../roles/harbor/package/{harbor-offline-installer-v1.1.2.tgz,docker-compose}
