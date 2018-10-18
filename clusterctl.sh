#!/bin/sh

~/go/bin/clusterctl create cluster --existing-bootstrap-cluster-kubeconfig ~/.kube/config -c ./spec/cluster.yaml -m ./spec/machines.yaml -p ./spec/provider-components.yaml --provider vsphere  -v 6
