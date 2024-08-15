The text in this document attempts to explain the process of managing an OpenShift 4 cluster. The major components used within are:

* Advanced Cluster Management (ACM)
  * ACM Policies to manage Day 1 concerns
* ArgoCD (Day 2 deployment/configuration)
* Helm

The specifics for the Day 1 and Day 2 deployments are found in their respective sections.

In general, a hub cluster (ACM) is deployed and configured. Next, ACM policies are added to ACM and the cluster starts to monitor policy compliance. 

After the hub cluster is configured, the automation engine, ArgCD, is deployed and various Argo Appsets are added into the automation framework to update the cluster's configuration including installation of components that are deemed essential for the running of the cluster.
