#!/bin/sh

# it requires the following enviroment variable:
# JUMPHOST
# GOVC_URL
# GOVC_USERNAME
# GOVC_PASSWORD
# VSPHERE_MACHINE_CONTROLLER_REGISTRY

# and it requires container has volumes
# /root/ssh/jumphost
# /root/ssh/bootstrapper

bootstrap_vm_ip=""
get_bootstrap_vm() {
   dc=$(govc find -type d)
   bootstrap_vm=$(govc find vm -name clusterapi-bootstrap)
   bootstrap_vm_name="${dc}/${bootstrap_vm}"
   snapshot_name="cluster-api-provider-vsphere-ci-0.0.1"
   govc snapshot.revert -vm "${bootstrap_vm_name}" "${snapshot_name}"  
   bootstrap_vm_ip=$(govc vm.ip "${bootstrap_vm_name}")
}

run_cmd_on_bootstrap() {
   ssh -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/ssh/jumphost -W %h:%p luoh@$JUMPHOST" \
       vmware@"$1" -i /root/ssh/bootstrapper -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" "$2"
}

delete_vm() {
   dc=$(govc find -type d)
   vm=$(govc find vm -name "$1""-*")
   govc vm.power -off "${dc}/${vm}"
   govc vm.destroy "${dc}/${vm}"
}

get_bootstrap_vm

controller_registry=${VSPHERE_MACHINE_CONTROLLER_REGISTRY:-luoh/cluster-api-provider-vsphere:0.0.11}
echo "test ${controller_registry}"
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "sed -i 's|{VSPHERE_MACHINE_CONTROLLER_REGISTRY}|'${controller_registry}'|g' ~/.config/envs"


provider_component=${PROVIDER_COMPONENT_SPEC:-provider-components-v1.0.yml}
echo "test ${provider_component}"
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "sed -i 's|{PROVIDER_COMPONENT_SPEC}|'${provider_component}'|g' ~/.config/envs"
# ssh to bootstrap VM and deploy the CI container to bootstrap cluster
job="kubectl create -f https://gist.githubusercontent.com/figo/989ede156d4a0d722244fb0c16d5ba80/raw/3a995366a08e361d0ca8d9892a82b580eda4b91b/job.yml"
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "${job}"

# wait for job to finish
run_cmd_on_bootstrap "${bootstrap_vm_ip}" "~/lib/wait_for_job_finished.sh 600"
ret="$?"

# cleanup
delete_vm "clusterapi-master"
get_bootstrap_vm

exit "${ret}"
