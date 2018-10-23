#!/bin/sh
set -x
# this script takes care of everything after bootstrap cluster created, it means
# bootstrap need be created beforehand.

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


# run clusterctl
./bin/clusterctl create cluster --existing-bootstrap-cluster-kubeconfig ~/.kube/config -c ./spec/cluster.yml -m ./spec/machines.yml -p ./spec/provider-components.yml --provider vsphere  -v 6


# cleanup the cluster
# TODO (clusterctl delete is not working, but does not support existing bootstrap cluster)
