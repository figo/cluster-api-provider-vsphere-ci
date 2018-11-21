#!/bin/sh

# Copyright 2018 The Kubernetes Authors.
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

# it requires the following enviroment variables:
# JUMPHOST
# GOVC_URL
# GOVC_USERNAME
# GOVC_PASSWORD
# VSPHERE_CONTROLLER_VERSION

# and it requires container has volumes
# /root/ssh/.jumphost/jumphost-key
# /root/ssh/.bootstrapper/bootstrapper-key

# the first argument should be the vsphere controller version

fill_file_with_value() {
  newfilename="$(echo "$1" | sed 's/template/yml/g')"
  rm -f "$newfilename" temp.sh  
  ( echo "cat <<EOF >$newfilename";
    cat "$1";
    echo "EOF";
  ) >temp.sh
  chmod +x temp.sh
  ./temp.sh
}

revert_bootstrap_vm() {
   dc=$(govc find -type d)
   bootstrap_vm=$(govc find vm -name clusterapi-bootstrap-prow)
   bootstrap_vm_name="${dc}/${bootstrap_vm}"
   snapshot_name="cluster-api-provider-vsphere-ci-0.0.1"
   govc snapshot.revert -vm "${bootstrap_vm_name}" "${snapshot_name}"  
   bootstrap_vm_ip=$(govc vm.ip "${bootstrap_vm_name}")
}

run_cmd_on_bootstrap() {
   ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/ssh/.jumphost/jumphost-key -W %h:%p luoh@$JUMPHOST" vmware@"$1" \
       -i "/root/ssh/.bootstrapper/bootstrapper-key" \
       -o "StrictHostKeyChecking=no" \
       -o "UserKnownHostsFile=/dev/null" "$2"
}

delete_vm() {
   dc=$(govc find -type d)
   vm=$(govc find vm -name "$1""-*")
   govc vm.power -off "${dc}/${vm}"
   govc vm.destroy "${dc}/${vm}"
}

get_bootstrap_vm() {
   export GOVC_INSECURE=1
   retry=10
   bootstrap_vm_ip=""
   until [ $bootstrap_vm_ip ]
   do
      sleep 6
      revert_bootstrap_vm
      retry=$((retry - 1))
      if [ $retry -lt 0 ]
      then
         break
      fi
   done

   if [ -z "$bootstrap_vm_ip" ] ; then
      echo "bootstrap vm ip is empty"
      exit 1
   fi
   echo "bootstrapper VM ip: ${bootstrap_vm_ip}"
}

apply_secret_to_bootstrap() {
   provider_component=${PROVIDER_COMPONENT_SPEC:=provider-components-v2.0.yml}
   export PROVIDER_COMPONENT_SPEC=$(echo -n "${provider_component}" | base64 -w 0)
   echo "test ${provider_component}"

   echo "test controller version $1"
   vsphere_controller_version="gcr.io/cnx-cluster-api/vsphere-cluster-api-provider:$1"
   export VSPHERE_CONTROLLER_VERSION=$(echo -n "${vsphere_controller_version}" | base64 -w 0)
   echo "test ${vsphere_controller_version}"

   export VSPHERE_SERVER=$(echo -n "${GOVC_URL}" | base64 -w 0)
   export VSPHERE_USERNAME=$(echo -n "${GOVC_USERNAME}" | base64 -w 0)
   export VSPHERE_PASSWORD=$(echo -n "${GOVC_PASSWORD}" | base64 -w 0)
   export TARGET_VM_SSH=$(echo -n "${TARGET_VM_SSH}" | base64 -w 0)
   export TARGET_VM_SSH_PUB=$(echo -n "${TARGET_VM_SSH_PUB}" | base64 -w 0)

   fill_file_with_value "bootstrap_secret.template"
   run_cmd_on_bootstrap "${bootstrap_vm_ip}" "cat > /tmp/bootstrap_secret.yml" < bootstrap_secret.yml
   run_cmd_on_bootstrap "${bootstrap_vm_ip}" "kubectl create -f /tmp/bootstrap_secret.yml"
}

start_docker() {
   service docker start
   # the service can be started but the docker socket not ready, wait for ready
   WAIT_N=0
   MAX_WAIT=5
   while true; do
      # docker ps -q should only work if the daemon is ready
      docker ps -q > /dev/null 2>&1 && break
      if [ ${WAIT_N} -lt ${MAX_WAIT} ]; then
         WAIT_N=$((WAIT_N+1))
         echo "Waiting for docker to be ready, sleeping for ${WAIT_N} seconds."
         sleep ${WAIT_N}
      else
         echo "Reached maximum attempts, not waiting any longer..."
         break
      fi
   done
}

clone_clusterapi_vsphere_repo() {
   mkdir -p /go/src/sigs.k8s.io/cluster-api-provider-vsphere
   git clone https://github.com/kubernetes-sigs/cluster-api-provider-vsphere.git \
             /go/src/sigs.k8s.io/cluster-api-provider-vsphere/
}

install_govc() {
   GOVC_VERSION=0.19.0
   go get -d github.com/vmware/govmomi
   git --work-tree /go/src/github.com/vmware/govmomi \
       --git-dir /go/src/github.com/vmware/govmomi/.git \
       checkout -b v${GOVC_VERSION} v${GOVC_VERSION} && \
   go install github.com/vmware/govmomi/govc
}

# the main loop
vsphere_controller_version="$1"
echo "build vSphere controller version: ${vsphere_controller_version}"
if [ -z "${PROW_JOB_ID}" ] ; then
   start_docker
   clone_clusterapi_vsphere_repo
   current=$(pwd)
   cd /go/src/sigs.k8s.io/cluster-api-provider-vsphere || exit 1
   export VERSION="${vsphere_controller_version}" && make ci-push
   cd "${current}" || exit 1
else
   # in Prow context, clusterapi-vsphere already been checked out
   export VERSION="${vsphere_controller_version}" && make ci-push
   cd ./../../figo/cluster-api-provider-vsphere-ci/prow || exit 1
fi

# get bootstrap VM
install_govc
get_bootstrap_vm

# apply secret at bootstrap cluster
apply_secret_to_bootstrap "${vsphere_controller_version}"

# launch the job at bootstrap cluster
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "cat > /tmp/bootstrap_job.yml" < bootstrap_job.yml
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "kubectl create -f /tmp/bootstrap_job.yml"

# wait for job to finish
run_cmd_on_bootstrap "${bootstrap_vm_ip}" 'bash -s' < wait_for_job.sh
ret="$?"

# cleanup
delete_vm "clusterapi-prow"
get_bootstrap_vm

exit "${ret}"
