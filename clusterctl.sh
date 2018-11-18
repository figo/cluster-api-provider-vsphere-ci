#!/bin/sh

# this script takes care of everything after bootstrap cluster created, it means
# bootstrap need be created beforehand.


# export necessary enviroment variables
echo "getting enviroment variable from $1"
. "$1"

# update specs, requires following enviroments variables:
# POD_CIDR
# VSPHERE_SERVER
# VSPHERE_USERNAME
# VSPHERE_PASSWORD
# VSPHERE_MACHINE_CONTROLLER_REGISTRY
# TARGET_VM_SSH  (base64 encoded)
# TARGET_VM_SSH_PUB (base64 encoded)

for filename in spec/*.template; do
  newfilename="$(echo "$filename" | sed 's/template/yml/g')"
  rm -f "$newfilename" temp.sh  
  ( echo "cat <<EOF >$newfilename";
    cat "$filename";
    echo "EOF";
  ) >temp.sh
  chmod +x temp.sh
  ./temp.sh
done
rm temp.sh


# download kubectl binary
wget https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# run clusterctl
echo "test ${PROVIDER_COMPONENT_SPEC}"
./bin/clusterctl create cluster --existing-bootstrap-cluster-kubeconfig ~/.kube/config -c ./spec/cluster.yml -m ./spec/machines.yml -p ./spec/${PROVIDER_COMPONENT_SPEC} --provider vsphere  -v 6

# cleanup the cluster
# TODO (clusterctl delete is not working, but does not support existing bootstrap cluster)
