# Deploying the ACM HUB OpenShift Cluster to VMware Environment

## Overview

This Ansible playbook facilitates the deployment of an OpenShift Hub cluster within a VMware environment. It leverages variables defined in `cluster-vars.yaml`.

### Workflow

1. **Template Processing**: Utilizes a Jinja template located at `/templates/install-config.yaml.j2` to generate `install-config.yaml`.
2. **Execution**: Executes the `openshift-install` command using the generated `install-config.yaml`.
3. **Output Directory**: Creates a directory under `/opt/OCP` named according to the target cluster.

### Usage Example
``` 
ansible-playbook -i inventory/ install-ipi.yaml --extra-vars="@cluster-vars.yaml"

```

The --extra-vars flag is used to define or override variables at runtime by passing them at the command line. This allows for dynamic input of values during playbook execution, which can be particularly useful for scenarios where certain values may change frequently or need to be customized for different runs of the same playbook.  


### Destroying a Cluster

To remove a cluster, execute:
```
openshift-install destroy cluster --dir /opt/OCP/<cluster_name> --log-level error

```

### Prerequisites prior to deployment

- OpenShift CLI (`oc`) and OpenShift Installer binaries installed on the bastion Linux server.
- Ansible installed on the bastion node.
- DNS resolution for API/Ingress endpoints.
- Networks allocated for OCP clusters (typically `/24` subnet).
- Port `443` accessibility on vCenter and ESXi hosts.
- Validation of service account permissions for vCenter interactions.
- Generation of SSH key pair for `install-config.yaml`, preferably from a shared user account.
- Retrieval and configuration of CA certificates from vCenter UI on the bastion host:

```
wget https://<vcenter_hostname>/certs/download.zip --no-check-certificate unzip download.zip &&
cat certs/lin/.0 > ca.yaml &&
cp certs/lin/ /etc/pki/ca-trust/source/anchors &&
update-ca-trust extract
```


## Deployment Process

Upon execution, the playbook initiates the deployment sequence:

1. Deploys the Bootstrap VM to vCenter.
2. Deploys the Masters to vCenter, and powers on the Masters.
3. Connects the VMs to the network.
4. The Bootstrap VM assumes control of the API IP address, pulls required images, and distributes them to the Masters.
5. Transfers operational control, including API management, to the Masters.
6. Deploys Workers.
7. Destroys the Bootstrap VM upon successful cluster setup.

Ensure all prerequisites are met before initiating the deployment process.


## Explanation and Installation of the Advanced Cluster Managment Operator

### Description of Advanced Cluster Management Operator in OpenShift

The Advanced Cluster Management (ACM) Operator in OpenShift is designed to simplify the management of multiple Kubernetes clusters across various environments. It provides comprehensive tools and functionalities to manage the lifecycle, security, and operations of Kubernetes clusters, whether they are located on-premises, in public clouds, or at the edge.

### How It Works

- **Lifecycle Management**: ACM offers full lifecycle management capabilities for OpenShift Container Platform clusters and partial lifecycle management for other Kubernetes distributions. This includes provisioning, updating, and deprovisioning clusters.
- **Multicluster Engine**: ACM leverages the multicluster engine, which is part of OpenShift Container Platform, to manage clusters. The multicluster engine provides features like hosted control planes (based on HyperShift), Hive for provisioning self-managed clusters, klusterlet agents for registering managed clusters, and the Infrastructure Operator for orchestrating installations on bare metal and vSphere.
- **Policy-Based Management**: ACM allows administrators to define policies that specify desired states for clusters. These policies can enforce security standards, resource quotas, and other operational requirements across all managed clusters.
- **Application Deployment and Management**: Through integration with OpenShift GitOps/Argo CD, ACM automates the deployment and management of applications across clusters, ensuring consistency and compliance.

### Utilization of Multicluster Engine

The multicluster engine plays a crucial role in ACM's operation by enabling several key functionalities:

- **Hosted Control Planes**: Leveraging HyperShift technology, ACM can manage OpenShift Container Platform clusters with hosted control planes, allowing for hyperscale operations.
- **Hive**: Hive provisions self-managed OpenShift clusters to the hub and completes initial configurations, facilitating easier management of these clusters.
- **klusterlet Agent**: This component registers managed clusters to the hub, enabling centralized management and policy enforcement.

### Installation and Configuration

To install ACM, users log into the OpenShift web console, navigate to the Operator Hub, search for Advanced Cluster Management for Kubernetes, and proceed with the installation. After installation, creating a `MultiClusterHub` Custom Resource (CR) instance is necessary for setting up the management hub. This process involves selecting Operators > Installed Operators > Advanced Cluster Management for Kubernetes > MultiClusterHub in the OpenShift web console, then clicking "Create instance of MultiClusterHub".

ACM creates namespaces such as `local-cluster`, `open-cluster-management-agent`, `open-cluster-management-agent-addon`, and `multicluster-engine` during its setup. These namespaces are essential for managing the ACM stack, so it's important to ensure they do not already exist before deploying the operator.

Once the operators `Advanced Cluster Management for Kubernetes` and `multicluster engine for Kubernetes` have finished installing, the hub cluster user interface will reload and provide the `All Clusters` and `local-cluster` menu items at the top of the user interface to allow swtiching from the RHACM cluster view to the local-cluster view. 

Refer to the [official documentation](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.9/html/install/index) for more details.  
