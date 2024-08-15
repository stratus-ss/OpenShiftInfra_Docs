# Velero Day 2 Component Deployment in OpenShift Using Argo CD

Velero is an open-source tool designed for safely backing up, restoring, and migrating Kubernetes cluster resources and persistent volumes. Deploying Velero as a Day 2 component in OpenShift environments enhances disaster recovery capabilities and operational resilience. This overview details the deployment process of Velero using Argo CD, leveraging Helm charts and ApplicationSets for automated and scalable deployments across multiple clusters.

## Deployment Process Overview

The deployment of Velero in an OpenShift environment is orchestrated through Argo CD, utilizing Helm charts and ApplicationSets. Here's a breakdown of the process:

### Step 1: Helm Chart Deployment

Argo CD deploys Velero using its official Helm chart. Helm simplifies the deployment and management of complex Kubernetes applications by packaging them into charts. The Velero Helm chart encapsulates all the Kubernetes resources required to deploy Velero, including Custom Resource Definitions (CRDs), RBAC roles, and the Velero deployment itself.

### Step 2: ApplicationSet Customization

Argo CD's ApplicationSet controller extends Argo CD's functionality to manage deployments across multiple clusters or environments. For Velero, an ApplicationSet is defined with parameters that dynamically generate values based on the cluster's characteristics. These dynamic values are substituted into the Helm chart's `values.yaml` file, customizing the Velero deployment for each specific cluster.

### Step 3: Creation of Necessary Resources

Upon successful installation of Velero, the next step involves creating the necessary resources for backup and restore operations, such as `BackupStorageLocation`, `VolumeSnapshotLocation`, and `Schedule` objects. These resources define how backups are stored, where volume snapshots are taken, and how frequently backups occur.

- **BackupStorageLocation**: Specifies the location where backups should be stored. This could be cloud storage like AWS S3, Google Cloud Storage, or Azure Blob Storage.
  
- **VolumeSnapshotLocation**: Defines where volume snapshots should be stored. This is crucial for backing up persistent volumes attached to applications.

- **Schedule**: Allows users to define backup schedules, specifying how often backups should occur and what resources should be included.

### Dynamic Configuration with Cluster Generator

A key feature of this deployment strategy is the use of a cluster generator within the ApplicationSet definition. This generator outputs values that replace placeholders in the Helm chart's `values.yaml` file, enabling dynamic customization of the Velero deployment. It can generate unique identifiers or select specific storage locations based on the cluster's name or location, ensuring that each Velero deployment is optimized for its environment.

For example, the following resources are deployed to the cluster based on the these specifications:

A cluster named "ocp-dev-1" is managed by the ACM hub cluster.  The velero day2 component uses this as its `values.yaml` file:

```
velero:
  configuration:
    backupStorageLocation:
      name: ""
      bucket: ""
    schedules:
      cluster-daily:
        storageLocation: ""

```

And the Argocd applicationset on the ACM hub cluster contains these parameter substitions:
```
          parameters:
          - name: velero.configuration.backupStorageLocation.name
            value: '{{.name}}'
          - name: velero.schedules.cluster-daily.storageLocation
            value: '{{.name}}'
          - name: velero.configuration.backupStorageLocation.bucket
            value: '{{.name}}'
```

The resulting manifests, after this processing, is applied to the clusters and will have its necessary values in place:

#### *BackupStorageLocation*
```
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: ocp-dev-1
  namespace: velero
spec:
[...]
  objectStorage:
    bucket: ocp-dev-1
  provider: aws
```


## Benefits of This Approach

Deploying Velero as a Day 2 component in OpenShift clusters using Argo CD and ApplicationSets offers several benefits:

- **Automation and Scalability**: Automates the deployment and configuration of Velero across multiple clusters, reducing manual intervention and scaling operations efficiently.
- **Customization**: Allows for dynamic customization of Velero deployments based on cluster-specific characteristics, optimizing backup strategies.
- **Consistency**: Ensures consistent deployment and configuration of Velero across all clusters, simplifying management and troubleshooting.
- **GitOps Principles**: Aligns with GitOps principles by defining infrastructure as code, enabling version control, audit trails, and easy rollbacks.
- **Resilience**: Enhances disaster recovery capabilities and operational resilience through automated backup and restore processes.
- **Flexibility**: Supports various storage backends and configurations tailored to each cluster's needs, improving disaster recovery readiness.
- **Security**: Securely manages backups and restores, leveraging Kubernetes native tools and best practices.

## Advantages of Using Helm Charts and ApplicationSets

Deploying Velero via Argo CD using Helm charts and ApplicationSets offers several advantages:

- **Simplified Management**: Helm charts encapsulate complex deployments, making them manageable and repeatable across environments.
- **Scalability**: ApplicationSets enable scalable deployments across numerous clusters with minimal manual intervention.
- **Customization**: Dynamic values substitution ensures tailored configurations per cluster, enhancing backup strategies.
- **Version Control**: Changes tracked in Git, facilitating audits and rollback capabilities.
- **Automation**: Streamlines deployment, reducing errors and ensuring consistency across environments.
- **Compliance**: Aligns with GitOps principles, providing a robust disaster recovery strategy.

Deploying Velero via Argo CD, leveraging Helm charts and ApplicationSets, showcases modern GitOps practices, enhancing operational efficiency and security.

