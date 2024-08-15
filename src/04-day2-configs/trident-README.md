# Trident Day 2 Component Deployment in OpenShift Using Argo CD

Trident is a dynamic storage provisioner for Kubernetes that provides persistent storage for containerized applications through integration with various storage backends. Deploying Trident in an OpenShift environment enhances the cluster's ability to manage stateful applications efficiently. This overview details the deployment process of the Trident Day 2 component using Argo CD, leveraging its ApplicationSet feature to automate the deployment across multiple clusters.

## Deployment Process Overview

The deployment of the Trident operator and its associated configurations in an OpenShift environment is orchestrated through Argo CD, utilizing Helm charts and ApplicationSets. Here's a breakdown of the process:

### Step 1: Helm Chart Deployment

Argo CD deploys the Trident operator using its official Helm chart. Helm simplifies the deployment and management of complex Kubernetes applications by packaging them into charts. The Trident Helm chart encapsulates all the Kubernetes resources required to deploy Trident, including Custom Resource Definitions (CRDs), RBAC roles, and the operator deployment itself.

### Step 2: ApplicationSet Customization

Argo CD's ApplicationSet controller extends Argo CD's functionality to manage deployments across multiple clusters or environments. For Trident, an ApplicationSet is defined with parameters that dynamically generate values based on the cluster's characteristics. These dynamic values are substituted into the Helm chart's `values.yaml` file, customizing the Trident deployment for each specific cluster.

### Step 3: TridentBackendConfig and StorageClass Creation

Upon successful installation of the Trident operator, the next step involves creating the necessary `TridentBackendConfig` and `StorageClass` resources. These resources are crucial for defining how Trident interacts with the underlying storage backend and how storage is provisioned for applications.

- **TridentBackendConfig**: Specifies the details of the storage backend, such as credentials, pool names, and other backend-specific parameters. The creation of `TridentBackendConfig` resources is automated using parameters defined in the ApplicationSet, ensuring that each cluster has a customized configuration tailored to its storage environment.
  
- **StorageClass**: Defines how a unit of storage is provisioned and managed. By creating a `StorageClass` resource that references Trident, OpenShift clusters can request storage from Trident, leveraging the configurations defined in the associated `TridentBackendConfig`.


### Dynamic Configuration with Cluster Generator

A key feature of this deployment strategy is the use of a cluster generator within the ApplicationSet definition. This generator outputs values that replace placeholders in the Helm chart's `values.yaml` file, enabling dynamic customization of the Trident deployment. For example, it can generate unique identifiers or select specific storage pools based on the cluster's name or location, ensuring that each Trident deployment is optimized for its environment.

For example, the following resources are current implementations of the `TridentBackendConfig` and the `StorageClass`:

#### *TridentBackEndConfig*
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

#### *StorageClass*
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

The above manifests have specific references to their pertinent values.yaml files to pull the needed information into these manifests.  However, in addition to this, the Argocd applicationset is evaluating the values.yaml files and making substitutions based on cluster labels and the `cluster generator` within the applicationset.  
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

#### *TridentBackEndConfig*

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

#### *StorageClass*

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
## Benefits of This Approach

Deploying Trident as a Day 2 component in OpenShift clusters using Argo CD and ApplicationSets offers several benefits:

- **Automation and Scalability**: Automates the deployment and configuration of Trident across multiple clusters, reducing manual intervention and scaling operations efficiently.
- **Customization**: Allows for dynamic customization of Trident deployments based on cluster-specific characteristics, optimizing storage provisioning strategies.
- **Consistency**: Ensures consistent deployment and configuration of Trident across all clusters, simplifying management and troubleshooting.
- **GitOps Principles**: Aligns with GitOps principles by defining infrastructure as code, enabling version control, audit trails, and easy rollbacks.


