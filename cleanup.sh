#!/bin/sh

kubectl delete deploy/clusterapi-apiserver
kubectl delete deploy/clusterapi-controllers
kubectl delete statefulsets/etcd-clusterapi

kubectl delete svc/etcd-clusterapi-svc
kubectl delete svc/clusterapi
