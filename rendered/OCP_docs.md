- [Introduction](#introduction)
- [Centralized Cluster Management](#centralized-cluster-management)
  - [ACM Setup](#acm-setup)
    - [Hub Cluster Installation](#deploying-the-acm-hub-openshift-cluster-to-vmware-environment)
    - [Machine Management In OCP](#machine-management-in-ocp)
    - [Machine Configuration](#node-machinesets-and-machineconfigpools-in-openshift-clusters)
    - [Spoke Cluster Deployment](#automating-spoke-cluster-deployment-with-rhacm-in-vmware)
  - [ACM Policies](#advanced-cluster-management-acm-policies)
- [Automation](#automation)
  - [ArgoCD](#openshift-gitops-operator-installation-argocd)
  - [ArgoCD - ApplicationSet](#use-of-the-argo-applicationset)
- [Day 2 Components](#day-2-components)
  - [Cert Manager](#leveraging-cert-manager-in-openshift-clusters-via-helm-chart)
  - [External Secrets Manager](#secrets-management-in-openshift-clusters)
  - [Trident Storage](#trident-day-2-component-deployment-in-openshift-using-argo-cd)
  - [Velero Backup](#velero-day-2-component-deployment-in-openshift-using-argo-cd)
  - [Customizing Routes](#customizing-routes)
  - [MetalLB](#metallb-1)

# Introduction

The text in this document attempts to explain the process of managing an OpenShift 4 cluster. The major components used within are:

* Advanced Cluster Management (ACM)
  * ACM Policies to manage Day 1 concerns
* ArgoCD (Day 2 deployment/configuration)
* Helm

The specifics for the Day 1 and Day 2 deployments are found in their respective sections.

In general, a hub cluster (ACM) is deployed and configured. Next, ACM policies are added to ACM and the cluster starts to monitor policy compliance.

After the hub cluster is configured, the automation engine, ArgCD, is deployed and various Argo Appsets are added into the automation framework to update the cluster's configuration including installation of components that are deemed essential for the running of the cluster.

# Centralized Cluster Management

## ACM Setup

When managing a fleet of clusters at scale, it is essential to have a good management tool on hand. While some may use Ansible, Chef, Puppet or a series of home-grown automations, Red Hat provides [Red Hat Advanced Cluster Management](https://access.redhat.com/products/red-hat-advanced-cluster-management-for-kubernetes) with its OpenShift Platform Plus subscription.

### Deploying the ACM HUB OpenShift Cluster to VMware Environment

#### Overview

This Ansible playbook facilitates the deployment of an OpenShift Hub cluster within a VMware environment. It leverages variables defined in `cluster-vars.yaml`.

##### Workflow

1. **Template Processing**: Utilizes a Jinja template located at `/templates/install-config.yaml.j2` to generate `install-config.yaml`.
2. **Execution**: Executes the `openshift-install` command using the generated `install-config.yaml`.
3. **Output Directory**: Creates a directory under `/opt/OCP` named according to the target cluster.

##### Usage Examplea

```
ansible-playbook -i inventory/ install-ipi.yaml --extra-vars="@cluster-vars.yaml"

```

The --extra-vars flag is used to define or override variables at runtime by passing them at the command line. This allows for dynamic input of values during playbook execution, which can be particularly useful for scenarios where certain values may change frequently or need to be customized for different runs of the same playbook.

##### Destroying a Cluster

To remove a cluster, execute:

```
openshift-install destroy cluster --dir /opt/OCP/<cluster_name> --log-level error

```

##### Prerequisites prior to deployment

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

#### Deployment Process

Upon execution, the playbook initiates the deployment sequence:

1. Deploys the Bootstrap VM to vCenter.
2. Deploys the Masters to vCenter, and powers on the Masters.
3. Connects the VMs to the network.
4. The Bootstrap VM assumes control of the API IP address, pulls required images, and distributes them to the Masters.
5. Transfers operational control, including API management, to the Masters.
6. Deploys Workers.
7. Destroys the Bootstrap VM upon successful cluster setup.

Ensure all prerequisites are met before initiating the deployment process.

### Machine Management In OCP

Configuration of the hosts running inside the OpenShift cluster are controlled by the Machine Config Controller. The controller reads the MachineConfig object and ensures that the desired configuration is created. This machine configuration defines everything Red Hat CoreOS needs to function according to your desired parameters.

When taking action on a cluster, it is useful to group types of servers together. For example, you might have Infrastructure nodes hosting ingress, Control Plane hosting ETCD and various types of workloads such as GPU and specialized compute which make up different types of worker nodes. This is called a MachineConfigPool. These ensure that you can control with some level of granularity, which group of nodes will have what percentage of nodes available during disruptive activities such as upgrades.

Machinesets are a part of the Machine API and they allow for the management of machine compute resources within an OpenShift cluster. Machinesets can work with the Cluster Autoscaler and Machine Autoscaler to automatically adjust the cluster size based on demand, ensuring efficient scaling and resource utilization.

The below diagram shows the relationship between MachineConfigs and MachineConfigPools. The labels used in the relationship below can be created with the MachineSet which defines the machine from a Kubernetes perspective.

![](../src/images/machineconfigs_ocp.png)

### Node Machinesets and MachineConfigPools in OpenShift Clusters

#### Machinesets

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

#### MachineConfigPool

Each directory also contains a file named `infra-mcp.yaml`, representing the MachineConfigPool resource. This resource is responsible for establishing the `infra` MachineConfigPool within the cluster, applicable through `oc apply -f <filename>`.

The primary function of this MachineConfigPool is to aggregate infrastructure nodes into a dedicated pool. This configuration is crucial for operations such as cluster upgrades, where nodes necessitate cordoning and draining for reboot post-upgrade. By recognizing the pool, the cluster maintains operational continuity by keeping a predetermined number of nodes active within the pool during upgrade processes. This approach streamlines the upgrade procedure by categorizing nodes into pools, aiming to limit the simultaneous downtime of nodes within a single pool to a manageable percentage.

For more information, the official documentation can be found here: [OCP 4.15 Machinesets](https://docs.openshift.com/container-platform/4.15/machine_management/creating-infrastructure-machinesets.html).

### Automating Spoke Cluster Deployment with RHACM in VMware

#### Introduction

This project focuses on automating the generation of manifests used by Hive in Red Hat Advanced Cluster Management for Kubernetes (RHACM) to orchestrate the creation of clusters. Specifically, it targets the deployment of spoke clusters within a VMware environment, leveraging RHACM's capabilities for multicluster management.

#### Technical Overview of Spoke Clusters in RHACM

A spoke cluster, from the perspective of Red Hat Advanced Cluster Management, is a Kubernetes cluster managed and monitored by a central hub cluster via the Multicluster Manager (MCMM). The MCMM serves as the orchestrator, overseeing the lifecycle of these spoke clusters across various environments, including VMware. This architecture enables centralized management, monitoring, and policy enforcement across multiple clusters, thereby enhancing security, compliance, and operational efficiency.

#### Role Structure for Managed Clusters

The project utilizes an Ansible role structure specifically designed for creating and managing clusters within RHACM. This structure includes:

- **Roles Directory**: Contains the `managed-clusters-role`, encapsulating the logic for deploying and managing clusters.
- **Templates**: Features Jinja2 templates for generating various Kubernetes manifest files essential for cluster setup, such as `managedcluster.yaml.j2`, `klusterletaddonconfig.yaml.j2`, and others.
- **Variables Files**: Located under `roles/managed-clusters-role/defaults/main`, these files define critical parameters for cluster deployment, including network configurations, image sets, and authentication details.

#### Important Variables Files

- **vsphere-vars.yml**: Specifies common variables applicable to all clusters, such as the base domain, network CIDRs, and the network type.
- **vsphere-secret-vars.yml**: Contains sensitive variables not intended for public visibility, including trust bundles, SSH keys, and credentials for VM deployments.

##### Security Note

Variables files that contain secrets, particularly those ending with `_secret`, must be encrypted using Ansible Vault if they are stored in publicly accessible source control management (SCM) systems. This measure ensures the confidentiality of sensitive information.

#### Deployment Steps

1. **Validation**: Ensure all variables in the configuration files are correctly set.
2. **Login to Hub Cluster**: Authenticate to the RHACM hub cluster CLI using `oc login`.
3. **Execute Playbook**: Run the Ansible playbook with the inventory file to initiate the creation of the necessary manifests:
   `ansible-playbook playbook.yml -i inventory/`
4. **Apply the `full-deploy` manifest**: The generated `full-deploy.yaml` file from the previous step can now be `oc apply -f` to the ACM cluster or the ansible playbook can have a task that will apply this to the ACM cluster.

Once the `full-deploy.yaml` is applied, the ACM cluster will begin the process of deploying the cluster. This can be observed in the ACM UI, under the `Infrastructure - Clusters` menu option.

This structured approach aligns with the RHACM cluster lifecycle management, facilitating efficient and secure deployment of spoke clusters within VMware environments.

## Advanced Cluster Management (ACM) Policies

Within the realm of Advanced Cluster Management (ACM), policies serve as a cornerstone for enforcing governance and compliance across managed clusters. This directory is dedicated to housing the policies that are operational within the ACM cluster, specifically targeting the `open-cluster-management-hub` namespace for uniformity and ease of management.

### Namespace Consideration

It is imperative to note that the `open-cluster-management-hub` namespace does not exist by default upon ACM installation. Consequently, one of the preliminary steps following ACM configuration involves the explicit creation of this namespace, underscoring its significance in the policy management landscape.

### Policy Framework

The foundational structure of an ACM policy is crafted to ensure comprehensive coverage and flexibility in governance. Here is an illustrative example of a policy skeleton:

```
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: 
  namespace: 
  annotations:
    policy.open-cluster-management.io/categories: 
    policy.open-cluster-management.io/controls: 
    policy.open-cluster-management.io/description: 
    policy.open-cluster-management.io/standards: 
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: 
        spec:
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: 
                kind: 
                metadata:
                  name: 
          remediationAction: 
          severity: 
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: 
  namespace: 
spec:
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: 
  namespace: 
placementRef:
  name: 
  apiGroup: 
  kind: 
subjects:
  - name: 
    apiGroup: 
    kind: 
```

This structure encapsulates several critical components:

- **API Version and Kind**: These fields denote the version of the policy API and the type of resource being defined, respectively.
- **Metadata**: This section contains essential information about the policy, including its name and various annotations for classification purposes.
- **Specifications (Spec)**: The core of the policy, detailing the templates it employs, its enabled/disabled state, and the prescribed action upon violation detection.

Annotations play a pivotal role in categorizing policies according to security standards, control categories, and specific controls being enforced. They facilitate a structured approach to policy management, aligning policies with recognized security frameworks such as NIST or PCI.

Policy templates within the specification allow for the creation of targeted policies applied to managed clusters. Each template can dictate its remediation strategy and severity level, offering granular control over governance enforcement.

The inclusion of Placement and PlacementBinding objects enables the selective application of policies across clusters or cluster sets, leveraging criteria such as cluster labels or clusterset memberships.

The remediation action specifies the policy's enforcement behavior, distinguishing between automatic correction (`enforce`) and violation reporting (`inform`), thereby allowing for flexible compliance management strategies.

The disabled flag provides a mechanism to toggle policy enforcement without necessitating policy deletion, offering administrative convenience and operational flexibility.

### Functional Policy example

The following policy is an example of a fully working policy used to implement 'etcd-encryption' on all clusters:

```
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: policy-etcd-encryption
  namespace: open-cluster-management-hub
  annotations:
    policy.open-cluster-management.io/categories: SC System and Communications Protection
    policy.open-cluster-management.io/controls: SC-28 Protection Of Information At Rest
    policy.open-cluster-management.io/description: etcd encryption
    policy.open-cluster-management.io/standards: NIST SP 800-53
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: enable-etcd-encryption
        spec:
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: config.openshift.io/v1
                kind: APIServer
                metadata:
                  name: cluster
                spec:
                  encryption:
                    type: aescbc
          pruneObjectBehavior: None
          remediationAction: enforce
          severity: low
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: enable-etcd-encryption-status-kubeapi
        spec:
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: operator.openshift.io/v1
                kind: KubeAPIServer
                metadata:
                  name: cluster
                status:
                  conditions:
                    - message: "All resources encrypted: secrets, configmaps"
                      reason: EncryptionCompleted
          pruneObjectBehavior: None
          remediationAction: enforce
          severity: low
  remediationAction: enforce
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: policy-etcd-encryption-placement
  namespace: open-cluster-management-hub
spec:
  clusterSets:
    - global                               
  predicates:
    - requiredClusterSelector:
        labelSelector:
          matchExpressions:
            - key: vendor
              operator: In
              values:
                - OpenShift
  tolerations:
    - key: cluster.open-cluster-management.io/unreachable
      operator: Exists
    - key: cluster.open-cluster-management.io/unavailable
      operator: Exists
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: policy-etcd-encryption-placement
  namespace: open-cluster-management-hub
placementRef:
  name: policy-etcd-encryption-placement
  apiGroup: cluster.open-cluster-management.io
  kind: Placement
subjects:
  - name: policy-etcd-encryption
    apiGroup: policy.open-cluster-management.io
    kind: Policy
```

In the above policy, take note of the following:

* `remediationAction: Enforce` -- The remediationAction field specifies how RHACM should respond when a cluster is found to be non-compliant with a policy. When set to Enforce, RHACM actively attempts to modify the cluster to bring it into compliance with the policy requirements. This action involves applying changes to the cluster configuration to align with the desired state defined by the policy. Essentially, Enforce automates the remediation process, reducing manual intervention required to maintain policy adherence across clusters. This option can be set to `remediationAction: Inform` if the governance policy should only need RHACM to take note of this event, and instead of automatically correcting the issue, and give the cluster admins control of manually resolving the violation.

* `severity` -- The severity field categorizes the importance or impact level of a policy violation. It helps prioritize issues and guide remediation efforts accordingly. Commonly used values include:
  * Low: Indicates minor deviations from the policy that may not significantly affect operations but should be addressed.
  * Medium: Represents moderate deviations that could potentially impact operations or security and warrant prompt attention.
  * High: Denotes critical violations that pose significant risks to operations, security, or compliance and require immediate remediation.
    By setting an appropriate severity level, organizations can better manage their response to policy violations, focusing resources on addressing the most critical issues first.

* `Placement`: The Placement section determines where and under what conditions a policy should be applied. It consists of several components:
  * `clusterSets`: A clusterset is a structured way to group clusters based on shared characteristics, enabling more effective policy enforcement. By default, ACM creates a `global` clusterset, containing the Hub cluster and all spoke clusters, as well as a `default` clusterset which is empty but can be used for cluster segregation. Clustersets can be created to accomodate any number of customer requirements, such as a clusterset based on geographical locations, cluster roles, environment differences, etc. There is no limit on the number of clustersets an admin can create.
    * `global`: When specified, the policy applies universally across all managed clusters within the scope of RHACM governance. This setting ensures consistent enforcement of critical policies without the need to specify individual clusters or selectors.

* `matchExpressions`:
  * `key`: Specifies the label key to match against.
  * `operator`: Defines the comparison operation to perform. Common operators include In, NotIn, Exists, and DoesNotExist.
  * `values`: Lists the values that the label key must have for the match to succeed.

For example, the policy above targets clusters labeled with `vendor=OpenShift`. This means the policy will only apply to clusters that have been labeled as being OpenShift vendors, allowing for targeted enforcement based on specific cluster characteristics.

### Summary of Current policies

As of this writing, the policies in place on the Hub cluster are used to:
* configure the ldap oauth and rbac components
* the groupsync operator installation/groupsync instance creation for admin and appdev teams
* the external dns operator installation.

The policies can and will change as the needs of the teams evolve over time.

# Automation

There are a lot of automation tools available to help manage a cluster. This guide, for example, uses a series of Ansible Playbooks to roll out new clusters and coordinate joining to Red Hat ACM. However, there may be very good reasons to use more than one automation tool (cluster standup vs cluster configuration for example). Red Hat provides a supported version of [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) in the form of OpenShift GitOps.

## OpenShift GitOps Operator Installation (Argocd)

OpenShift GitOps introduces a paradigm shift in deploying and managing applications across OpenShift clusters by adhering to GitOps methodologies. This integration enhances the OpenShift ecosystem by providing a unified platform for GitOps workflows, simplifying the automation of Day 2 operations such as application deployment, configuration management, and cluster upgrades.

### Installation Process

The OpenShift GitOps Operator is seamlessly integrated into the OpenShift ecosystem via the OperatorHub available in the OpenShift Web Console's Administrator perspective. By navigating to Operators → OperatorHub, searching for "OpenShift GitOps," and proceeding with the installation prompts, the operator is deployed across all namespaces within the cluster. This straightforward installation process ensures that OpenShift GitOps is readily available for managing cluster-wide operations.

### Automatic Setup of Argo CD Instance

Post-installation, the Red Hat OpenShift GitOps Operator automates the setup of an operational Argo CD instance within the `openshift-gitops` namespace. This automation facilitates immediate access to the Argo CD dashboard through an icon conveniently located in the console toolbar, streamlining the management experience.

### Centralized Management Model for Day 2 Operations

The centralized model of OpenShift GitOps (Argo CD) plays a pivotal role in managing Day 2 configurations across multiple OpenShift clusters. By running a single Argo CD instance on an OpenShift Hub cluster, it centralizes the management of configurations and applications across connected OpenShift Spoke clusters. This model leverages GitOps principles to ensure consistent and automated deployments, thereby simplifying Day 2 operations such as application upgrades, configuration changes, and cluster scaling.

### Technical Implementation

The centralized Argo model requires visibility into managed clusters through Advanced Cluster Management (ACM). This visibility is achieved by creating a clusterset in the ACM hub, binding the OpenShift GitOps namespace to the managed clusterset via a clustersetbinding, and establishing placements and gitopscluster objects to tie the Argo CD instance to the managed clusters. These configurations enable Argo CD to utilize secrets containing cluster information for application deployment across the managed clusters.

The files contained within this directory create those necessary resources in the cluster.

### Considerations

- Clusters under ACM management must be part of the clusterset for Argo CD visibility.
- Due to resource demands, increasing application pod memory resources in the `openshift-gitops` namespace is recommended to prevent potential OOMKilled errors, as per guidance found at [Red Hat Solution 6260191](https://access.redhat.com/solutions/6260191).
- By default, an admin user and password are enabled post-installation, facilitating access to the Argo instance via username and password fields in the UI. Disabling this feature removes these fields, leaving only OpenShift login options available.

OpenShift GitOps significantly enhances Day 2 operations automation by providing a robust framework for managing applications and configurations across OpenShift clusters through GitOps methodologies, offering a streamlined approach to deploying applications and managing configurations consistently across environments. Its integration with OpenShift and utilization of Git repositories as the single source of truth ensures operational consistency and efficiency, making it an indispensable tool for Day 2 operations automation within OpenShift environments.

## Use of the Argo Applicationset

### Enhancing Operational Efficiency with Argo ApplicationSets

In our ongoing quest to modernize our IT operations, we've embraced a GitOps methodology, which aligns closely with our goal of achieving seamless, automated deployments. A pivotal component of this approach is Argo CD, a tool that embodies the principles of GitOps for Kubernetes environments. Within our Argo CD setup, we employ an Argo Application Set, specifically named day2-appset, to manage our Day 2 operations with unparalleled efficiency.

### Applicationset Overview

Argo ApplicationSets are a powerful feature within Argo CD designed to automate and enhance the management of multiple Argo CD Applications across numerous clusters. It introduces a scalable and efficient method for defining and orchestrating deployments, especially beneficial in complex environments involving many clusters or large monorepos.

#### Key Features and Benefits
* Multi-Cluster Support: ApplicationSet automates the creation and management of Argo CD Applications for each targeted cluster, significantly reducing manual efforts and potential errors.
* Monorepo Deployments: Simplifies the deployment of multiple applications contained within a single repository by leveraging templating to dynamically generate Argo CD Applications based on predefined patterns or criteria.
* Self-Service for Unprivileged Users: Facilitates a secure self-service model, allowing developers without direct access to the Argo CD namespace to deploy applications, streamlining operations and enhancing security.
* Templated Automation: Enables automated generation of Argo CD Applications based on templates defined within an ApplicationSet resource, supporting dynamic deployments tailored to various environments or configurations.

#### How ApplicationSet Works

The ApplicationSet controller operates alongside Argo CD, typically within the same namespace. It monitors for newly created or updated ApplicationSet Custom Resources (CRs) and automatically constructs corresponding Argo CD Applications according to the specifications defined in these CRs.

#### Example ApplicationSet Resource

Below is an example of an ApplicationSet resource targeting multiple clusters:

```
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - list:
      elements:
      - cluster: engineering-dev
        url: https://1.2.3.4
      - cluster: engineering-prod
        url: https://2.4.6.8
      - cluster: finance-preprod
        url: https://9.8.7.6
  template:
    metadata:
      name: '{{.cluster}}-guestbook'
    spec:
      project: my-project
      source:
        repoURL: https://github.com/infra-team/cluster-deployments.git
        targetRevision: HEAD
        path: guestbook/{{.cluster}}
      destination:
        server: '{{.url}}'
        namespace: guestbook
```

This resource defines a set of clusters (engineering-dev, engineering-prod, finance-preprod) and specifies the deployment details for a guestbook application across these clusters.

### The Role of day2-appset

The day2-appset plays a critical role in our Argo CD architecture, serving exclusively the ACM (Advanced Cluster Management) hub cluster instance. Its main objective is to facilitate the deployment of Day 2 configurations—configurations that come into play after the initial setup, such as operator installations and application deployments—from a designated Git repository to the most suitable clusters. This process is guided by a strategic placement strategy and employs advanced templating techniques to tailor deployments to each cluster's unique requirements.

### Strategic Placement and Dynamic Templating

Central to the day2-appset is a sophisticated placement strategy that precisely targets which clusters receive the Day 2 configurations. This strategy is informed by labels assigned to each cluster, enabling highly targeted deployments. Furthermore, the day2-appset leverages Go templating to dynamically generate application definitions that are perfectly suited to each cluster's specifics. This templating process draws upon information from both the Git repository and the cluster itself, ensuring that the configurations deployed are optimally adapted to the receiving environment.

A particularly noteworthy aspect of this templating is the conditional logic embedded within the `spec.source.path` field. This logic, using the results of an if/else statement, evaluates the presence of specific labels on the cluster, such as `cluster=default` and `env=<environment>`, to decide from which Git folder to deploy the configurations. This flexibility allows us to tailor deployments to different environments (development, testing, production) or accommodate custom configurations for specific clusters.
Example Usage: `{{if eq "default" .metadata.labels.cluster }}<folder name>{{ .metadata.labels.env }}/{{index .path.segments 1}}{{else}}{{ .name }}/{{index .path.segments 1}}{{end}}`

### Dynamic Naming and Namespace Selection

Building on the adaptability of our deployments, the day2-appset utilizes Go templating within the `.spec.template` section to dynamically name the Day 2 configurations and select the appropriate namespace for deployment. This process ensures that each deployment is uniquely identified and placed within the correct namespace, streamlining management and monitoring efforts.

### Tailoring Deployments for Custom Clusters

For clusters requiring custom configurations, the day2-appset accommodates by allowing the replication of Day 2 configurations from environment-specific folders to a custom folder. This approach ensures that all necessary components are available in the custom folder, ready for customization as needed.

In this specific environment, the Argo ApplicationSet utilizes distinct cluster labels present on the spoke clusters, specifically `cluster=default` and `cluster=custom`, to ascertain the directory from which Argo CD should initiate the deployment of its Day 2 components. When a cluster is designated with the label `cluster=custom`, Argo CD proceeds to deploy its Day 2 components from a directory within the Git repository that corresponds to the name of the cluster itself. For instance, if a cluster is identified as "ocp-test-cluster" and tagged with the `cluster=custom` label, Argo CD will seek out a directory labeled "ocp-test-cluster" within the Git repository to source its Day 2 components for deployment.

### Special Handling for Velero and Trident

Certain Day 2 configurations, notably Velero for backup solutions and Trident for storage provisioning, necessitate additional considerations. The day2-appset addresses these needs by incorporating specific parameter definitions within the Helm chart deployments. These parameters dynamically insert the cluster name and other relevant details into the configuration, ensuring that Velero and Trident are correctly configured for each environment.

*Excerpt from the day2-appset within the `openshift-gitops` namespace:*

```
source:
  helm:
    parameters:
    - name: velero.configuration.backupStorageLocation.name # Velero
      value: '{{.name}}'
    - name: velero.schedules.cluster-daily.storageLocation # Velero
      value: '{{.name}}'
    - name: velero.configuration.backupStorageLocation.bucket # Velero
      value: '{{.name}}'
    - name: config.name  # Trident
      value: '{{.name}}'
    - name: config.managementLIF # Trident
      value: '{{ .metadata.labels.netappLIF }}'
    - name: config.dataLIF # Trident
      value: '{{ .metadata.labels.netappLIF }}'
```

The day2-appset exemplifies our commitment to leveraging cutting-edge technology to enhance operational efficiency and consistency. By harnessing the power of Argo CD and GitOps principles, we've streamlined the deployment of Day 2 configurations across our clusters, ensuring that our infrastructure remains aligned with our strategic objectives. This approach not only reduces complexity but also empowers our team to focus on innovation and value creation.

*For more information on Argo ApplicationSets, see the [official documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/).*

# Day 2 Components

Day 2 components, for the purposes of this guide, are defined as any component that is required to be in place before the cluster can handle workload. A Day 1 component by contrast, is any component that directly impacts the base platform (such as SSO, machine sizes, Role Based Authentication and so on).

In this case Day 2 components enable customization of the cluster, allow traffic to flow to applications, providing a variety of storage classes for applications to consume as well as tools to backup workloads and their data.

## Leveraging cert-manager in OpenShift Clusters via Helm Chart

Cert-manager is an open-source native Kubernetes certificate management controller that automates the management and issuance of TLS certificates from various sources, including Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self-signed. It is particularly crucial in OpenShift clusters, given the dynamic nature of containerized applications that necessitate secure communication channels.

### Importance of cert-manager

In cloud-native architectures, services often communicate over HTTPS to ensure data privacy and integrity. Manual management of TLS certificates in such environments can be cumbersome and error-prone. Cert-manager automates this process, significantly reducing operational overhead and minimizing security risks associated with expired or misconfigured certificates.

- **Automated Certificate Lifecycle Management**: Cert-manager automatically renews certificates before they expire, ensuring uninterrupted service availability.
- **Integration with Multiple Certificate Authorities (CAs)**: It supports various certificate authorities, allowing organizations to choose the CA that best fits their compliance and security requirements.
- **Native Kubernetes Integration**: Being a native Kubernetes controller, cert-manager seamlessly integrates with Kubernetes resources and workflows, simplifying deployment and management.
- **Security Compliance**: Automated certificate management helps maintain security posture and compliance with industry standards by ensuring valid and up-to-date certificates.

### How cert-manager Works

Cert-manager operates by watching events from the Kubernetes API server and responding to challenges from certificate authorities (CAs) to prove ownership of domain names. It consists of several components:

- **cert-manager Controller**: Manages Certificate resources and ensures they are issued and renewed.
- **Webhook Solver**: Handles ACME (Automatic Certificate Management Environment) challenges for domain validation.
- **CA Injector**: Injects CA certificates into Kubernetes Secrets for use by other components.

The workflow typically involves creating a `Certificate` resource that specifies the desired state, such as the domains to cover, the issuer to use, and the location to store the issued certificate. Cert-manager then coordinates with the specified issuer to obtain a certificate meeting the criteria defined in the `Certificate` resource.

### Deployment via Argo CD Using Helm Chart

In the current environment, OpenShift clusters managed through Advanced Cluster Management (ACM) and Argo CD, cert-manager is deployed using its Helm chart. This approach leverages the power of Helm, a package manager for Kubernetes, to simplify the deployment and management of cert-manager. The deployment is orchestrated by Argo CD, which utilizes an ApplicationSet to manage deployments across multiple clusters or environments.

The use of the Helm chart for cert-manager deployment is facilitated by enabling the `enable-helm` flag in the ApplicationSet definition within Argo CD. This flag instructs Argo CD to treat the specified source as a Helm chart, allowing for the seamless integration of Helm-based applications into the GitOps workflow.

Deploying cert-manager via Argo CD using Helm charts offers several benefits:

- **Version Control**: Changes to cert-manager configurations are tracked in version control, enabling audit trails and rollback capabilities.
- **Automated Updates**: Argo CD can automatically apply updates to cert-manager, ensuring that the latest features and security patches are applied without manual intervention.
- **Consistency Across Environments**: By defining cert-manager configurations in Git, organizations can easily replicate consistent setups across multiple environments, such as staging, testing, and production.

This method of deploying cert-manager exemplifies the synergy between GitOps practices, Helm charts, and automated certificate management in achieving robust, secure, and efficient cloud-native environments. It streamlines certificate management, enhances security posture, and reduces operational complexity, making it an essential component in modern Kubernetes-based infrastructures.

## Secrets Management in OpenShift Clusters

Secrets management is a critical aspect of securing applications and services within an OpenShift cluster. It involves the creation, storage, rotation, and access control of sensitive information such as passwords, API keys, certificates, and other credentials required by applications and services to function securely. Effective secrets management minimizes operational overhead associated with maintaining secrets outside the cluster while providing a secure mechanism for utilizing secrets within the cluster environment.

### Importance of Secrets Management

In the context of OpenShift clusters, robust secrets management is paramount for several reasons:

- **Security**: Ensuring that sensitive information is encrypted at rest and in transit protects against unauthorized access and potential security breaches.
- **Compliance**: Adhering to industry standards and regulations often requires stringent management of secrets, including regular rotation and audit trails.
- **Operational Efficiency**: Automating the lifecycle of secrets reduces manual intervention, thereby minimizing the risk of human error and enhancing operational efficiency.
- **Scalability**: As applications scale, managing secrets manually becomes increasingly complex. A centralized secrets management solution simplifies scaling operations securely.

### OpenShift Secrets Management Capabilities

OpenShift provides built-in mechanisms for managing secrets, leveraging Kubernetes' Secret resource type. These capabilities are designed to address the challenges associated with secrets management in containerized environments:

- **Encryption at Rest**: OpenShift supports encryption of etcd data, where secrets are stored, ensuring that sensitive information is protected even if the underlying storage is compromised.
- **Role-Based Access Control (RBAC)**: Fine-grained access control policies can be applied to secrets, ensuring that only authorized users and applications can access them.
- **Secrets Rotation**: While OpenShift itself does not automatically rotate secrets, integration with external secrets management tools can automate this process, enhancing security posture.
- **Integration with External Secrets Management Solutions**: OpenShift clusters can be integrated with third-party secrets management solutions such as HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault. This integration provides advanced features like dynamic secrets, centralized policy enforcement, and audit logging.

### Operational Considerations

When implementing secrets management within an OpenShift cluster, several operational considerations should be taken into account:

- **Lifecycle Management**: Establish processes for creating, updating, and deleting secrets as part of the application lifecycle.
- **Access Controls**: Implement RBAC policies to restrict access to secrets based on the principle of least privilege.
- **Monitoring and Auditing**: Utilize OpenShift's built-in monitoring and auditing capabilities to track access to secrets and detect unauthorized attempts.
- **External Integrations**: Evaluate and integrate with external secrets management solutions to leverage advanced features and comply with organizational policies.

### External Secrets for Day 2 Components

The management of external secrets for Day 2 components is facilitated through an external secrets component, which is currently deployed using Argo CD. The deployment and utilization of these external secrets follow a structured process:

1. **Creation of "azure-secret"**: Initially, a secret named "azure-secret" must be manually created on each cluster within the `external-secrets` namespace. This secret serves as the foundation for accessing external secrets.

2. **Deployment of ClusterSecretStore**: Subsequently, a `ClusterSecretStore` named "azure-shared-store" is established on the cluster via an ACM policy titled `acm-policy-es-secretstore`. This store acts as a bridge between the cluster and the external secrets management system.

3. **Utilization by Day 2 Components**: Once the `ClusterSecretStore` is validated and operational on the cluster, it becomes available for use by other Day 2 components such as `cert-manager`, `velero`, and `splunk`. These components can securely access the necessary secrets without manual intervention, streamlining operations and enhancing security.

This approach to managing external secrets not only automates the provisioning and rotation of secrets but also ensures that sensitive information is handled securely and efficiently across the cluster environment. By leveraging Argo CD for deployment and integrating with ACM policies, organizations can maintain a robust and scalable secrets management strategy that supports the secure operation of Day 2 components within OpenShift clusters.

## Trident Day 2 Component Deployment in OpenShift Using Argo CD

Trident is a dynamic storage provisioner for Kubernetes that provides persistent storage for containerized applications through integration with various storage backends. Deploying Trident in an OpenShift environment enhances the cluster's ability to manage stateful applications efficiently. This overview details the deployment process of the Trident Day 2 component using Argo CD, leveraging its ApplicationSet feature to automate the deployment across multiple clusters.

### Deployment Process Overview

The deployment of the Trident operator and its associated configurations in an OpenShift environment is orchestrated through Argo CD, utilizing Helm charts and ApplicationSets. Here's a breakdown of the process:

#### Step 1: Helm Chart Deployment

Argo CD deploys the Trident operator using its official Helm chart. Helm simplifies the deployment and management of complex Kubernetes applications by packaging them into charts. The Trident Helm chart encapsulates all the Kubernetes resources required to deploy Trident, including Custom Resource Definitions (CRDs), RBAC roles, and the operator deployment itself.

#### Step 2: ApplicationSet Customization

Argo CD's ApplicationSet controller extends Argo CD's functionality to manage deployments across multiple clusters or environments. For Trident, an ApplicationSet is defined with parameters that dynamically generate values based on the cluster's characteristics. These dynamic values are substituted into the Helm chart's `values.yaml` file, customizing the Trident deployment for each specific cluster.

#### Step 3: TridentBackendConfig and StorageClass Creation

Upon successful installation of the Trident operator, the next step involves creating the necessary `TridentBackendConfig` and `StorageClass` resources. These resources are crucial for defining how Trident interacts with the underlying storage backend and how storage is provisioned for applications.

- **TridentBackendConfig**: Specifies the details of the storage backend, such as credentials, pool names, and other backend-specific parameters. The creation of `TridentBackendConfig` resources is automated using parameters defined in the ApplicationSet, ensuring that each cluster has a customized configuration tailored to its storage environment.

- **StorageClass**: Defines how a unit of storage is provisioned and managed. By creating a `StorageClass` resource that references Trident, OpenShift clusters can request storage from Trident, leveraging the configurations defined in the associated `TridentBackendConfig`.

#### Dynamic Configuration with Cluster Generator

A key feature of this deployment strategy is the use of a cluster generator within the ApplicationSet definition. This generator outputs values that replace placeholders in the Helm chart's `values.yaml` file, enabling dynamic customization of the Trident deployment. For example, it can generate unique identifiers or select specific storage pools based on the cluster's name or location, ensuring that each Trident deployment is optimized for its environment.

For example, the following resources are current implementations of the `TridentBackendConfig` and the `StorageClass`:

##### *TridentBackEndConfig*

```
---
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: "{{ .Values.config.name }}" 
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-nas
  managementLIF: "{{ .Values.config.managementLIF }}"   
  dataLIF: "{{ .Values.config.dataLIF }}"              
  backendName: "{{ .Values.config.name }}"
  storagePrefix: kube
  nfsMountOptions: nfsvers=4
  credentials:
    name: netapp-ontap-secret
  defaults:
    spaceReserve: none
    exportPolicy: myk8scluster
```

##### *StorageClass*

```
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: "{{ .Values.config.name }}"
  annotations: 
    storageclass.kubernetes.io/is-default-class: "true"  
parameters:
  backendType: ontap-nas
  provisioningType: thin
  storagePools: '"{{ .Values.config.name }}":.*'
provisioner: csi.trident.netapp.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

The above manifests have specific references to their pertinent values.yaml files to pull the needed information into these manifests. However, in addition to this, the Argocd applicationset is evaluating the values.yaml files and making substitutions based on cluster labels and the `cluster generator` within the applicationset.
For a cluster named `ocp-dev-cluster1`, that has a label of `svm_IP=10.1.1.1`, and the corresponding trident `values.yaml` file has the references of:

```
config:
  name: ""
  dataLIF: ""
  managementLIF: ""
```

And the argocd applicationset contains these parameter substitions:

```
          - name: config.name
            value: '{{.name}}'
          - name: config.managementLIF
            value: '{{ .metadata.labels.netappLIF }}'
          - name: config.dataLIF
            value: '{{ .metadata.labels.netappLIF }}'
```

The resulting manifests, after this processing, is applied to the clusters and will have its necessary values in place:

##### *TridentBackEndConfig*

```
---
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata: ocp-dev-cluster1
  name: 
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-nas
  managementLIF: 10.1.1.1
  dataLIF: 10.1.1.1
  backendName: ocp-dev-cluster1
  storagePrefix: kube
  nfsMountOptions: nfsvers=4
  credentials:
    name: netapp-ontap-secret
  defaults:
    spaceReserve: none   
    exportPolicy: myk8scluster
```

##### *StorageClass*

```
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocp-dev-cluster1
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
parameters:
  backendType: ontap-nas
  provisioningType: thin
  storagePools: ocp-dev-cluster1:.*'
provisioner: csi.trident.netapp.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### Benefits of This Approach

Deploying Trident as a Day 2 component in OpenShift clusters using Argo CD and ApplicationSets offers several benefits:

- **Automation and Scalability**: Automates the deployment and configuration of Trident across multiple clusters, reducing manual intervention and scaling operations efficiently.
- **Customization**: Allows for dynamic customization of Trident deployments based on cluster-specific characteristics, optimizing storage provisioning strategies.
- **Consistency**: Ensures consistent deployment and configuration of Trident across all clusters, simplifying management and troubleshooting.
- **GitOps Principles**: Aligns with GitOps principles by defining infrastructure as code, enabling version control, audit trails, and easy rollbacks.

> **Note**
> The trident operator, once installed on the cluster, creates its own storageclass and marks this storageclass as `default`. This will conflict with the *out-of-the-box* storageclass `thin-csi` as it is also marked as `default`. The Openshift cluster will choose the `default` storageclass first to handle its storage operations, therefore, the `thin-csi` storageclass needs to have this `default` label marked to *false* like so:

```
oc patch storageclass thin-csi -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
```

## Velero Day 2 Component Deployment in OpenShift Using Argo CD

Velero is an open-source tool designed for safely backing up, restoring, and migrating Kubernetes cluster resources and persistent volumes. Deploying Velero as a Day 2 component in OpenShift environments enhances disaster recovery capabilities and operational resilience. This overview details the deployment process of Velero using Argo CD, leveraging Helm charts and ApplicationSets for automated and scalable deployments across multiple clusters.

### Deployment Process Overview

The deployment of Velero in an OpenShift environment is orchestrated through Argo CD, utilizing Helm charts and ApplicationSets. Here's a breakdown of the process:

#### Step 1: Helm Chart Deployment

Argo CD deploys Velero using its official Helm chart. Helm simplifies the deployment and management of complex Kubernetes applications by packaging them into charts. The Velero Helm chart encapsulates all the Kubernetes resources required to deploy Velero, including Custom Resource Definitions (CRDs), RBAC roles, and the Velero deployment itself.

#### Step 2: ApplicationSet Customization

Argo CD's ApplicationSet controller extends Argo CD's functionality to manage deployments across multiple clusters or environments. For Velero, an ApplicationSet is defined with parameters that dynamically generate values based on the cluster's characteristics. These dynamic values are substituted into the Helm chart's `values.yaml` file, customizing the Velero deployment for each specific cluster.

#### Step 3: Creation of Necessary Resources

Upon successful installation of Velero, the next step involves creating the necessary resources for backup and restore operations, such as `BackupStorageLocation`, `VolumeSnapshotLocation`, and `Schedule` objects. These resources define how backups are stored, where volume snapshots are taken, and how frequently backups occur.

- **BackupStorageLocation**: Specifies the location where backups should be stored. This could be cloud storage like AWS S3, Google Cloud Storage, or Azure Blob Storage.

- **VolumeSnapshotLocation**: Defines where volume snapshots should be stored. This is crucial for backing up persistent volumes attached to applications.

- **Schedule**: Allows users to define backup schedules, specifying how often backups should occur and what resources should be included.

#### Dynamic Configuration with Cluster Generator

A key feature of this deployment strategy is the use of a cluster generator within the ApplicationSet definition. This generator outputs values that replace placeholders in the Helm chart's `values.yaml` file, enabling dynamic customization of the Velero deployment. For example, it can generate unique identifiers or select specific storage locations based on the cluster's name or location, ensuring that each Velero deployment is optimized for its environment.

### Benefits of This Approach

Deploying Velero as a Day 2 component in OpenShift clusters using Argo CD and ApplicationSets offers several benefits:

- **Automation and Scalability**: Automates the deployment and configuration of Velero across multiple clusters, reducing manual intervention and scaling operations efficiently.
- **Customization**: Allows for dynamic customization of Velero deployments based on cluster-specific characteristics, optimizing backup strategies.
- **Consistency**: Ensures consistent deployment and configuration of Velero across all clusters, simplifying management and troubleshooting.
- **GitOps Principles**: Aligns with GitOps principles by defining infrastructure as code, enabling version control, audit trails, and easy rollbacks.
- **Resilience**: Enhances disaster recovery capabilities and operational resilience through automated backup and restore processes.
- **Flexibility**: Supports various storage backends and configurations tailored to each cluster's needs, improving disaster recovery readiness.
- **Security**: Securely manages backups and restores, leveraging Kubernetes native tools and best practices.

### Advantages of Using Helm Charts and ApplicationSets

Deploying Velero via Argo CD using Helm charts and ApplicationSets offers several advantages:

- **Simplified Management**: Helm charts encapsulate complex deployments, making them manageable and repeatable across environments.
- **Scalability**: ApplicationSets enable scalable deployments across numerous clusters with minimal manual intervention.
- **Customization**: Dynamic values substitution ensures tailored configurations per cluster, enhancing backup strategies.
- **Version Control**: Changes tracked in Git, facilitating audits and rollback capabilities.
- **Automation**: Streamlines deployment, reducing errors and ensuring consistency across environments.
- **Compliance**: Aligns with GitOps principles, providing a robust disaster recovery strategy.

Deploying Velero via Argo CD, leveraging Helm charts and ApplicationSets, showcases modern GitOps practices, enhancing operational efficiency and security.

## Customizing Routes

### Custom Routes

#### OpenShift Console

In order to customize the route for the OpenShift web console you will need to have a DNS entry present if the console URL will not be part of the wild card DNS entry. Additionally, if the domain suffix is being changed or you simply want to have a specific SSL certificate for the web UI, additional work is required.

##### Custom Certificates

By default, any secret referenced by the ingress controller needs to be created in the **openshift-config** namespace. In case this is missing from your cluster you can create this with the following command:

```
oc create namespace openshift-config
```

> [!NOTE]
> Normally you should be using `oc new-project`, however creation of some projects are restricted by the OpenShift API (such as any project starting with `openshift-`).
> Using `oc create namespace` uses the kubernetes primitives and gets around these restrictions. USE WITH CAUTION!

To create the secret use the following command template:

```
oc create secret tls <secret name> --cert=path/to/tls.crt --key=path/to/tls.key -n openshift-config
```

##### Editing The Ingress Controller

You can edit the ingress controller with the following command:

```
oc edit ingress.config.openshift.io cluster
```

You can edit the `spec` section so it looks like this:

```
spec:
  componentRoutes:
    - name: console
      namespace: openshift-console
      hostname: <hostname> 
      servingCertKeyPairSecret:
        name: <secret_name> 
```

Saving and exiting the editor will cause some pods to restart. The console will be unavailable until the pods have finished their restart procedures.

## MetalLB

### MetalLB

#### Helm Chart Version

In some cases it may be desirable to forgo the Operator install from Operator Hub and install MetalLB directly from the upstream Helm chart. This approach provides maximal flexibility and may integrate with existing workflows around Helm Chart deployments.

In order to get a local copy of the Helm Chart, you can add the repo to your cluster:

```
helm repo add metallb https://metallb.github.io/metallb
```

Next, you can use the `helm pull` command to grab the tarball for local editing or storage:

```
helm pull metallb/metallb
```

Untar the tarball:

```
tar xvf metallb-*.tar
```

The main advantage to this approach instead of installing it directly into the cluster with a `helm install` command is that you can customize the Helm Chart and extend it if needed. You will also have a point of reference for any automation (such as ArgoCD) that you may implement.

With that in mind, the Helm Chart can be installed with the default `values.yaml` file (without modification) that ships with the tarball:

```
helm install metallb metallb/metallb -f values.yaml 
```

> [!NOTE]
> When installing to a project in OpenShift *other* than `default` there are additional permissions which MetalLB requires.
> The Helm Chart creates the `metallb-speaker` and `metallb-controller` accounts which need elevated privileges which can be added with the following commands:
>
> ```
> oc adm policy add-scc-to-user anyuid -z metallb-speaker
> oc adm policy add-scc-to-user privileged -n metallb -z metallb-speaker
> oc adm policy add-scc-to-user privileged -n metallb -z metallb-controller 
> ```
>
> Use these commands with caution as they allow extra privileges that the OpenShift security model normally restricts!

Future enhancements to the above process could include
* Editing the Helm Chart to adjust for permissions without running additional commands
* Setting a default project such as `openshift-metallb` to allow for consistant installations

#### Configuration

After the Helm Chart is installed, MetalLB needs to be configured. The pods will deploy without configuration, however VMs or Pods will not receive IPs until MetalLB is properly configured.

The first step is to create an `L2Advertisment`. This file can be used for [advanced configuration](https://metallb.universe.tf/configuration/_advanced_l2_configuration/) including such things as determinging which IP AddressPools to use and which nodes will be available.

A basic L2Adverisement looks like this:

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: <unique name>
  namespace: <namespace of metallb>
```

See the above documentation for more indepth options.

Similarly, the `IPAddressPool` defines either address ranges or network CIDRs. You can see more details [here](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/). A basic example can be seen below:

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: <pool name>
  namespace: <metallb namespace>
spec:
  addresses:
  - 192.168.94.40-192.168.94.70
```

The final step is to tell OpenShift services to use MetalLB. [The official documentation](https://docs.openshift.com/container-platform/4.15/networking/metallb/metallb-configure-services.html#metallb-configure-services) provides various scenarios that you might consider. A basic example that will accept any IP Address from MetalLB would look like this:

```
apiVersion: v1
kind: Service
metadata:
  name: <service_name>
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  type: LoadBalancer
```

This service will then expose the port `8080` over the IP address which it receives from MetalLB.
