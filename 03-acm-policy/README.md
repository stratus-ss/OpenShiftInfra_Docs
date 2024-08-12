# ACM Policies

This directory houses policies utilized in the ACM cluster.

The policies in use on the ACM cluster are applied in the `open-cluster-management-hub` namespace.
This namespace was chosen for simplicity and consistency.  

> [!NOTE]
> The `open-cluster-management-hub` namespace is not a namespace created "out of the box" after ACM is installed, therefore, one of the early primary steps after ACM is configured is to create this namespace.   

## Policy Structure

The basic policy is as follows (with example policy skeleton used for reference:

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

This policy is composed of the following:
* `apiVersion:` Specifies the version of the policy API, typically `policy.open-cluster-management.io/v1`.
* `kind:` Indicates the type of resource, which is `Policy` for ACM policies.
* `metadata:` Contains metadata about the policy, such as its name and annotations.
* `spec:` Defines the specifics of the policy, including the templates it uses, whether it's enabled or disabled, and the action to take upon violation.

* Annotations: Annotations within the metadata allow for further classification of the policy:

* `policy.open-cluster-management.io/standards:` Names of security standards the policy relates to, e.g., NIST, PCI.
* `policy.open-cluster-management.io/categories:` Security control categories representing specific requirements for one or more standards.
* `policy.open-cluster-management.io/controls:` Names of the security controls being checked, e.g., certificate policy controller.
* Policy Templates: The spec.policy-templates section is used to create one or more policies to apply to managed clusters. Each template can specify its own remediation action and severity level.
* Placement and PlacementBinding:  Used to enable policy to a cluster or a set of clusters using options such as the clusterset or cluster labels. 
* Remediation Action:  The `remediationAction` field specifies how violations should be handled, with options typically including enforce (automatically correct violations) and inform (report violations without taking corrective action).
* Disabled Flag: The `disabled` flag allows enabling or disabling the policy without deleting it.
