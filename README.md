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
   
   
***Containers***  
the vsphere-machine-controller containers for CI purpose are hosted at `luoh/cluster-api-provider-vsphere`  
the cluster-api-provider-vsphere-travis-ci hosted at `luoh/cluster-api-provider-vsphere-travis-ci`  
the cluster-api-provider-vsphere-ci hosted at `luoh/cluster-api-provider-vsphere-ci`  
the [job spec](https://gist.githubusercontent.com/figo/989ede156d4a0d722244fb0c16d5ba80/raw/3a995366a08e361d0ca8d9892a82b580eda4b91b/job.yml) for cluster-api-provider-vsphere-ci  
 

***Integrate with Prow (WIP)***
```

            +-----------------------------------------------------+
            |                                                     |
            |                                                     |
            |        container running on Prow cluster:           |
            |                                                     |
            |        create bootstrap cluster (on VMC)            |
            |        transfer secret from Prow to bootstrap       |
            |        launch a ci job at bootstrap                 |
            |        monitor job status                           |
            |                                                     |
            |                                                     |
            |                                                     |
            |                                                     |
            |                                                     |
            |                                                     |
            |                             +---------------------+ |
            |                             |  secret             | |
            |                             +---------------------+ |
            +-----------------------------------------------------+


           +-------------------------------------------------------+
           |        +--------------------------------------------+ |
           |        |  secret: target VM SSH, bootstrap cluster  | |
           |        |  kubeconfig, vsphere info                  | |
           |        |                                            | |
           |        +--------------------------------------------+ |
           |                                                       |
           |        +--------------------------------------------+ |
           |        |  configMap: pod_cidr, mc_registry_url,     | |
           |        |             provider_component_spec_version| |
           |        |                                            | |
           |        +--------------------------------------------+ |
           |                                                       |
           |                             +-----------------------+ |
           |                             |                       | |
           |                             |     CI job:           | |
           |                             | create target cluster | |
           |                             | on VMC                | |
           |                             +-----------------------+ |
           |                                                       |
           |        BOOTSTRAP CLUSTER (on VMC)                     |
           |                                                       |
           +-------------------------------------------------------+
```  
