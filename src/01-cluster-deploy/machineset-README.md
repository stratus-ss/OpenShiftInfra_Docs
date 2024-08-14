# Node Machinesets and MachineConfigPools in OpenShift Clusters

## Machinesets

Machinesets are employed within this repository to provision the requisite nodes for individual OpenShift clusters. Each cluster-specific Machineset is instrumental in deploying infrastructure nodes equipped with the necessary resources. This allocation enables the cluster to delegate specific workloads from master and worker nodes to infrastructure nodes, addressing two primary objectives:

- Mitigating subscription cost implications by optimizing resource utilization.
- Facilitating segregated maintenance and management protocols.

Infrastructure nodes typically handle the following workload categories:

- Routing
- Monitoring
- Logging
- Registry operations
- Service mesh implementations

Machinesets are organized into directories corresponding to each cluster, with filenames adhering to the `<cluster-name>-infra-ms.yaml` convention. Post-cluster deployment, these files can be customized with relevant vCenter information and the OpenShift-specific 'infra-id'. Application of these configurations is achieved via the command `oc apply -f <filename>`.

Following the deployment and activation of infrastructure nodes, router pods can be migrated to these nodes. This migration is facilitated by the `ingress-controller.yaml` file present in this directory. Upon confirmation of infrastructure node availability, executing `oc apply -f ingresscontroller.yaml` transfers the `router-default` pods (residing in the `openshift-ingress` namespace) to the infrastructure nodes, ensuring a one-to-one correspondence between `router-default` pods and infrastructure nodes.

## MachineConfigPool

Each directory also contains a file named `infra-mcp.yaml`, representing the MachineConfigPool resource. This resource is responsible for establishing the `infra` MachineConfigPool within the cluster, applicable through `oc apply -f <filename>`.

The primary function of this MachineConfigPool is to aggregate infrastructure nodes into a dedicated pool. This configuration is crucial for operations such as cluster upgrades, where nodes necessitate cordoning and draining for reboot post-upgrade. By recognizing the pool, the cluster maintains operational continuity by keeping a predetermined number of nodes active within the pool during upgrade processes. This approach streamlines the upgrade procedure by categorizing nodes into pools, aiming to limit the simultaneous downtime of nodes within a single pool to a manageable percentage.


For more information, the official documentation can be found here: [OCP 4.15 Machinesets](https://docs.openshift.com/container-platform/4.15/machine_management/creating-infrastructure-machinesets.html).
