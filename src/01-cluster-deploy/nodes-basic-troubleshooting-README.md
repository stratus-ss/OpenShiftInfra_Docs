# Establishing Secure Shell Access to OpenShift Cluster Nodes for Diagnostic Purposes
In the phase preceding the deployment of an OpenShift Container Platform (OCP) cluster, a specification of an SSH key within the install-config.yaml file ensures the seamless integration of secure communication channels between the deployment initiator and the cluster's foundational elements. Specifically, during the installation process, an imprint of the public key is stored within the bootstrap node and the subsequent cluster nodes, thereby establishing a cryptographic foundation for secure interactions.

Equipped with the corresponding private key, one gains the capability to initiate secure shell sessions (SSH) towards these instances, facilitating direct interaction and inspection. The invocation of such sessions is exemplified through the following command:

`ssh -i <path_to_ssh_key> core@<ip_address_of_node>`

The importance of this method of node access becomes particularly evident during the diagnostic phase of a cluster deployment that may have encountered unforeseen challenges. By leveraging SSH, one can establish a connection to the most recently deployed set of nodes and engage in a detailed examination of system logs, employing the journalctl command as a tool for introspection and analysis.


> **_NOTE:_** The utilization of SSH access is only recommended for disaster recovery scenarios and/or troubleshooting failed cluster deployments.

> :information_source: **Info**:
Should the necessity arise to update the SSH keys post-deployment, a comprehensive guide detailing the necessary steps can be found at the following URL: [Red Hat Solution 3868301](https://access.redhat.com/solutions/3868301). 
