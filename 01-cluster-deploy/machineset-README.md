# Node Machinesets and Machineconfigpools

## Machinesets
The machinesets within this directory and used per cluster in order to create the necessary nodes for the Openshift clusters.  Each cluster machineset is used to deploy the infra nodes with the needed resources to allow fo the cluster to offload specific workloads off the masters and workers and handover to the infra nodes.  This is important for 2 primary reasons:
* to prevent incurring billing costs against subscription counts and
* to separate maintenance and management.  

The workloads generally associated with the infra nodes are:
* routing
* monitoring
* logging
* registry

Each machineset is specific to the cluster, therefore they are divided up by directories named after the cluster.  The file within the directory is notated with a `<cluster-name>-infra-ms.yaml` nomenclature.  Once a cluster is built, this file can be edited with the proper vcenter information and openshift specific 'infra-id' and can be applied with an `oc apply -f <filename>`.  

Once the infra nodes are deployed and online, the router pods can be moved over to them.  This is accomplished with a file in this directory called `ingress-controller.yaml`.  After validating the infra nodes are up, you can `oc apply -f ingresscontroller.yaml` to the cluster.  This will move the router-default pods (in the openshift-ingress namespace) to the infra nodes.  There will be one `router-default` pod per infra node. 

## Machineconfigpool

There is a file in each directory called `infra-mcp.yaml`.  This is the machineconfigpool resource that will create the `infra` mcp on the cluster.  This can be `oc apply -f` to the cluster.  The purpose of this machineconfigpool is to create a pool for the infra nodes.  This is iportant for operations such as upgrades, where the cluster will need to cordon and drain the nodes after an upgrade for a reboot.  The cluster will see the pool and keep a certain number of nodes up from the pool while it works on a node.  This will allow a more refined upgrade process as it delineates the nodes by pool and make an effort to only pull a percentage of nodes down per pool.  
