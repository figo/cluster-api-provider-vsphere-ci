#!/bin/sh

minikube start --bootstrapper=kubeadm --network-plugin=cni --vm-driver=vmware
