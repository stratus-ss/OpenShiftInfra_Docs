# ACM Managed Cluster Generator
This project is to used to create a the manifests used by hive in [Red Hat Advanced Cluster Management for kubernetes \(RHACM\)](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.9/) generate clusters.

##Example Usage
1.) Validate all variables are correct
2.) 'oc login' to Hub cluster cli
3.) ansible-playbook playbook.yml -i inventory/


## Role
```
roles/
└── managed-clusters-role
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── README.md
    ├── tasks
    │   └── main.yml
    ├── templates
    │   ├── cluster-install-config-secret.yaml.j2
    │   ├── klusterletaddonconfig.yaml.j2
    │   ├── managedcluster.yaml.j2
    │   ├── pull-secret.yaml.j2
    │   ├── ssh-key.yaml.j2
    │   ├── vs-ca-certs.yaml.j2
    │   ├── vs-certs.yaml.j2
    │   ├── vs-clusterdeployment.yaml.j2
    │   ├── vs-creds.yaml.j2
    │   ├── vs-infra-machinepool.yaml.j2
    │   ├── vs-install-config.yaml.j2
    │   └── vs-worker-machinepool.yaml.j2
    └── vars
        └── main
            ├── main.yml
            ├── secret.yml
            ├── vsphere_secret.yml
            └── vsphere.yml
```

### Important vars files
N.B. The vars files exist under `roles/managed-cluster-role/defaults/main` directory.

All variable files that have `secret` in their name should be [ansible-vault](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html) encrypted if these are being saved on a publically readable SCM. 

#### vsphere-vars.yml
This contains common variables that are applicable to all clusters.

`basedomain` : The domain name for the cluster.

`imageset` : The version of OpenShift to start from.  This should match the ImageSet object available to your cluster.

`clustercidr` : Network cidr to use for the cluster.

`servicecidr` : Network cidr for the service network of the cluster.

`ocp_networkType` : Network type to use for the install.  N.B.  OCP 4.12 changes the default to `OVNKubernetes` 

`infra` : Boolean determining whether to create infractructure machine pools by default.

`addtionalTags` : A YAML dictionary of additional labels to add to a managed cluster.

#### vsphere-secret-vars.yml
This contains common variables that are applicable to all clusters but this info should NOT be publically visible.  See the `N.B.` above.

`trustBundle` : The additional CA bundle to use if you have your own private Certificate Authority.

`ssh_public_key` : Public ssh key to be used at install.  This variable doesn't need to be encrypted as it is the PUBLIC key but it is kept in here with the `ssh_private_key` to ease of location.

`ssh_private_key` : Private ssh key to be used at install.

`username` : the username used to deply the vms to vcenter

`password` : associated password for the vm deployment username.
