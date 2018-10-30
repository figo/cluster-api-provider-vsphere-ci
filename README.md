Test cluster-api-provider-vsphere

***Launch CI***
```
docker run \
  --rm \
  -v $HOME/.ssh:/root/ssh \
  -e GOVC_URL=$GOVC_URL \
  -e GOVC_USERNAME=$GOVC_USERNAME \
  -e GOVC_PASSWORD=$GOVC_PASSWORD \
  -e JUMPHOST=$JUMPHOST \
  -e GOVC_INSECURE="true" \
  -e VSPHERE_MACHINE_CONTROLLER_REGISTRY=$VSPHERE_MACHINE_CONTROLLER_REGISTRY \
  -ti luoh/cluster-api-provider-vsphere-travis-ci:latest
```
note: set `$VSPHER_MACHINE_CONTROLLER_REGISTRY` if you want to test your local build controller


***Architecture***
```

                                             +-----------------------------------+
      +----------------------+               |          VMC Infra                |
      |   travis-ci env      |               |-----------------------------------|
      |----------------------|               |+----+ +--------------------------+|
      |                      |               ||    | |  bootstrap cluster       ||
      |                      |               ||    | |                          ||
      | cluster-api-vsphere- |               ||JUMP| |  cluster-api-vsphere-ci  ||
      | travis-ci            |  SSH + HTTP   ||HOST| |  (a k8s job)             ||
      |                      | +-----------> ||    | |                          ||
      |                      | <-----------+ ||    | |                          ||
      |                      |               ||    | +--------------------------+|
      |                      |               ||    |                             |
      |                      |               ||    | +--------------------------+|
      |                      |               ||    | |  target cluster          ||
      |                      |               ||    | |                          ||
      |                      |               ||    | |                          ||
      |                      |               |+----+ +--------------------------+|
      +----------------------+               +-----------------------------------+
                                             
```
