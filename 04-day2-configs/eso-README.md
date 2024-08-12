## External Secrets

The external secrets for the day2 components are handled through this external secrets component, currently being installed with Argo.    

Once Argo installs, the logical flow of this should follow these steps for each cluster:
1.)  A secret called "azure-secret" will still need to be created on the cluster in the `external-secrets` namespace. 
2.)  The `ClusterSecretStore` called "azure-shared-store" will then be created on the cluster through an ACM policy called `acm-policy-es-secretstore`
3.) Once that secret store is validated on the cluster, it is ready to be utilized by the other day2 components such `cert-manager`, `velero`, and `splunk`.
