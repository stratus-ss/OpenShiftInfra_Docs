# Hub cluster gitops 

## Overview
OpenShift GitOps, powered by Argo CD, is designed to streamline the deployment and management of applications on OpenShift clusters through GitOps principles. When installed on an OpenShift 4 cluster, OpenShift GitOps integrates seamlessly with the OpenShift ecosystem, providing a robust platform for implementing GitOps workflows. 

Here's a synopsis of how it operates:

### Installation Process
Installation via OperatorHub 
OpenShift GitOps is installed through the OpenShift Web Console's Administrator perspective by navigating to Operators → OperatorHub. Searching for "OpenShift GitOps" and clicking the tile leads to the installation process. Upon completion, OpenShift GitOps is deployed across all namespaces of the cluster 2.
### Automatic Setup of Argo CD Instance 
After installation, the Red Hat OpenShift GitOps Operator automatically sets up a ready-to-use Argo CD instance in the openshift-gitops namespace. An Argo CD icon appears in the console toolbar, facilitating easy access to the Argo CD dashboard.

### Workflow
With OpenShift GitOps, deploying applications becomes a matter of syncing Git repositories. This approach ensures that the state of the cluster mirrors the desired state defined in the Git repository, adhering to GitOps principles. Applications can be deployed by adding them as Argo CD applications, specifying the Git repository, path, destination, and other relevant parameters.



## The centralized argo model
The OpenShift GitOps (also known as Argo CD) centralized model for managing Day 2 configurations across multiple OpenShift clusters involves running a single Argo CD instance on an OpenShift Hub cluster. This setup centralizes the management of configurations and applications across all connected OpenShift Spoke clusters, leveraging GitOps principles for consistent and automated deployments.

In order for the centralized argo model to work, argo needs visiblility from the ACM cluster to deploy applications to the managed clusters.  The purpose of the files in this directory is to provide that visiblity.  

The files themselves accomplish the following:
* Creates a clusterset in the ACM hub.
* Creates a `clustersetbinding` to bind the `openshift-gitops` namespace to that `managed` clusterset.
* Creates a `placement` for the clusterset and `openshift-gitops` namespace to tie to the managed clusters.
* Creates an object called `gitopscluster`' which ties the Argocd instance residing in the `openshift-gitops` namespace to the managed clusters in ACM.

Once the clusters reside in the clusterset and the argo namespace (usually `openshift-gitops`) is added to that managedclusterset, and the placement and gitopscluster object created, the `openshift-gitops` namespace will then populate with secrets containing the clusters info, such as labels and the like.  Once the secrets are created, argo then utilizes those secrets for its use in the appset.  

> [!NOTE]
> The clusters in ACM will need to reside in the "clusterset" for Argo to have visiblity to see those clusters. Therefore, the clusters will need to be moved to that clusterset.  

> [!NOTE]
> Due to the demand of resources of the centralized Argo model, it is best to increase the application pod memory resources in the openshift-gitops namespace (as directed here: https://access.redhat.com/solutions/6260191) to accomodate the high demand of the arog instance and avoid any `OOMKilled` errors from the application pod.  

> [!NOTE]
> The admin user and password is enabled by default after the openshift-gitops operator is installed.  This admin user will allow a user to log into the argo instance using the `username` and `password` fields in the UI.  Should this be disabled, the `username` and `password` fields in the UI will disappear, leaving just the Openshift login option to be present. 
