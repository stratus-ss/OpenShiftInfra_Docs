When managing a fleet of clusters at scale, it is essential to have a good management tool on hand. While some may use Ansible, Chef, Puppet or a series of home-grown automations, Red Hat provides [Red Hat Advanced Cluster Management](https://access.redhat.com/products/red-hat-advanced-cluster-management-for-kubernetes) with its OpenShift Platform Plus subscription. It operates on a hub-and-spoke model, centralizing the management of multiple Kubernetes clusters from a single console. The hub acts as the central management point, overseeing multiple managed clusters (the spokes). This architecture enables centralized management, policy enforcement, and monitoring across all connected clusters.

The following diagram outlines some of the interactions at a high level between the Hub and the Managed (spoke) cluster:

![](../src/images/ACM1.png)

While it is possible to create and destroy clusters from ACM itself. This document outlines using an Ansible Playbook to communicate with vSphere in order to create clusters to specification. Once the cluster is created, it is then joined to ACM through the same playbook. 