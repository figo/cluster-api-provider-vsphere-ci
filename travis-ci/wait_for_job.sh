#!/bin/sh

TOTAL=600
INTERVAL=6
retry=$((${TOTAL}/ INTERVAL))
ret=0
until kubectl get jobs --no-headers | awk -F" " '{print $2}' | awk -F"/" '{s+=($1!=$2)} END {exit s}';
do
   sleep ${INTERVAL};
   retry=$((retry - 1))
   if [ $retry -lt 0 ];
   then
      ret=1
      echo "job timeout"
      break
   fi;
   kubectl get jobs --no-headers;
done;
echo "all jobs finished";

pod_name=$(kubectl get pods -a --no-headers | grep cluster-api-provider-vsphere-ci | awk -F" " '{print $1}')
kubectl logs "${pod_name}"
exit ${ret}
