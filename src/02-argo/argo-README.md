# OpenShift GitOps Operator Installation (Argocd)

OpenShift GitOps, leveraging Argo CD, introduces a paradigm shift in deploying and managing applications across OpenShift clusters by adhering to GitOps methodologies. This integration enhances the OpenShift ecosystem by providing a unified platform for GitOps workflows, simplifying the automation of Day 2 operations such as application deployment, configuration management, and cluster upgrades.

## Installation Process

The OpenShift GitOps Operator is seamlessly integrated into the OpenShift ecosystem via the OperatorHub available in the OpenShift Web Console's Administrator perspective. By navigating to Operators → OperatorHub, searching for "OpenShift GitOps," and proceeding with the installation prompts, the operator is deployed across all namespaces within the cluster. This straightforward installation process ensures that OpenShift GitOps is readily available for managing cluster-wide operations.

## Automatic Setup of Argo CD Instance

Post-installation, the Red Hat OpenShift GitOps Operator automates the setup of an operational Argo CD instance within the `openshift-gitops` namespace. This automation facilitates immediate access to the Argo CD dashboard through an icon conveniently located in the console toolbar, streamlining the management experience.

## Centralized Management Model for Day 2 Operations

The centralized model of OpenShift GitOps (Argo CD) plays a pivotal role in managing Day 2 configurations across multiple OpenShift clusters. By running a single Argo CD instance on an OpenShift Hub cluster, it centralizes the management of configurations and applications across connected OpenShift Spoke clusters. This model leverages GitOps principles to ensure consistent and automated deployments, thereby simplifying Day 2 operations such as application upgrades, configuration changes, and cluster scaling.

## Technical Implementation

The centralized Argo model requires visibility into managed clusters through Advanced Cluster Management (ACM). This visibility is achieved by creating a clusterset in the ACM hub, binding the OpenShift GitOps namespace to the managed clusterset via a clustersetbinding, and establishing placements and gitopscluster objects to tie the Argo CD instance to the managed clusters. These configurations enable Argo CD to utilize secrets containing cluster information for application deployment across the managed clusters.

The files contained within this directory create those necessary resources in the cluster.

## Considerations

- Clusters under ACM management must be part of the clusterset for Argo CD visibility.
- Due to resource demands, increasing application pod memory resources in the `openshift-gitops` namespace is recommended to prevent potential OOMKilled errors, as per guidance found at [Red Hat Solution 6260191](https://access.redhat.com/solutions/6260191).
- By default, an admin user and password are enabled post-installation, facilitating access to the Argo instance via username and password fields in the UI. Disabling this feature removes these fields, leaving only OpenShift login options available.

OpenShift GitOps significantly enhances Day 2 operations automation by providing a robust framework for managing applications and configurations across OpenShift clusters through GitOps methodologies, offering a streamlined approach to deploying applications and managing configurations consistently across environments. Its integration with OpenShift and utilization of Git repositories as the single source of truth ensures operational consistency and efficiency, making it an indispensable tool for Day 2 operations automation within OpenShift environments.

