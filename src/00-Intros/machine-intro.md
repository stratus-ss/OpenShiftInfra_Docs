Configuration of the hosts running inside the OpenShift cluster are controlled by the Machine Config Controller. The controller reads the MachineConfig object and ensures that the desired configuration is created. This machine configuration defines everything Red Hat CoreOS needs to function according to your desired parameters.

When taking action on a cluster, it is useful to group types of servers together. For example, you might have Infrastructure nodes hosting ingress, Control Plane hosting ETCD and various types of workloads such as GPU and specialized compute which make up different types of worker nodes. This is called a MachineConfigPool. These ensure that you can control with some level of granularity, which group of nodes will have what percentage of nodes available during disruptive activities such as upgrades.

Machinesets are a part of the Machine API and they allow for the management of machine compute resources within an OpenShift cluster. Machinesets can work with the Cluster Autoscaler and Machine Autoscaler to automatically adjust the cluster size based on demand, ensuring efficient scaling and resource utilization. 

The below diagram shows the relationship between MachineConfigs and MachineConfigPools. The labels used in the relationship below can be created with the MachineSet which defines the machine from a Kubernetes perspective.

![](../src/images/machineconfigs_ocp.png)