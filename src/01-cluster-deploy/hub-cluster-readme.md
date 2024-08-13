# Deploying the ACM HUB OpenShift Cluster to VMware Environment

## Overview

This Ansible playbook facilitates the deployment of an OpenShift Hub cluster within a VMware environment. It leverages variables defined in `cluster-vars.yaml`.

### Workflow

1. **Template Processing**: Utilizes a Jinja template located at `/templates/install-config.yaml.j2` to generate `install-config.yaml`.
2. **Execution**: Executes the `openshift-install` command using the generated `install-config.yaml`.
3. **Output Directory**: Creates a directory under `/opt/OCP` named according to the target cluster.

### Usage Examplea
```ansible-playbook -i inventory/ install-ipi.yaml --extra-vars="@cluster-vars.yaml"

```

### Destroying a Cluster

To remove a cluster, execute:
```openshift-install destroy cluster --dir /opt/OCP/<cluster_name> --log-level error

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

```bash wget https://<vcenter_hostname>/certs/download.zip --no-check-certificate unzip download.zip &&
cat certs/lin/.0 > ca.yaml &&
cp certs/lin/ /etc/pki/ca-trust/source/anchors &&
update-ca-trust extract```


## Deployment Process

Upon execution, the playbook initiates the deployment sequence:

1. Deploys the Bootstrap VM to vCenter.
2. Powers on the Master and Worker VMs.
3. Connects the VMs to the network.
4. The Bootstrap VM assumes control of the API IP address, pulls required images, and distributes them to the Masters.
5. Transfers operational control, including API management, to the Masters.
6. Deploys Workers.
7. Destroys the Bootstrap VM upon successful cluster setup.

Ensure all prerequisites are met before initiating the deployment process.
