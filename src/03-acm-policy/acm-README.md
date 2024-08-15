# Advanced Cluster Management (ACM) Policies

Within the realm of Advanced Cluster Management (ACM), policies serve as a cornerstone for enforcing governance and compliance across managed clusters. This directory is dedicated to housing the policies that are operational within the ACM cluster, specifically targeting the `open-cluster-management-hub` namespace for uniformity and ease of management.

## Namespace Consideration

It is imperative to note that the `open-cluster-management-hub` namespace does not exist by default upon ACM installation. Consequently, one of the preliminary steps following ACM configuration involves the explicit creation of this namespace, underscoring its significance in the policy management landscape.

## Policy Framework

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


## Functional Policy example

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

* `remediationAction:  Enforce` -- The remediationAction field specifies how RHACM should respond when a cluster is found to be non-compliant with a policy. When set to Enforce, RHACM actively attempts to modify the cluster to bring it into compliance with the policy requirements. This action involves applying changes to the cluster configuration to align with the desired state defined by the policy. Essentially, Enforce automates the remediation process, reducing manual intervention required to maintain policy adherence across clusters.  This option can be set to `remediationAction: Inform` if the governance policy should only need RHACM to take note of this event, and instead of automatically correcting the issue, and give the cluster admins control of manually resolving the violation.

* `severity` -- The severity field categorizes the importance or impact level of a policy violation. It helps prioritize issues and guide remediation efforts accordingly. Commonly used values include:
  * Low: Indicates minor deviations from the policy that may not significantly affect operations but should be addressed.
  * Medium: Represents moderate deviations that could potentially impact operations or security and warrant prompt attention.
  * High: Denotes critical violations that pose significant risks to operations, security, or compliance and require immediate remediation.
By setting an appropriate severity level, organizations can better manage their response to policy violations, focusing resources on addressing the most critical issues first.

* `Placement`: The Placement section determines where and under what conditions a policy should be applied. It consists of several components:
  * `clusterSets`: A clusterset is a structured way to group clusters based on shared characteristics, enabling more effective policy enforcement.  By default, ACM creates a `global` clusterset, containing the Hub cluster and all spoke clusters, as well as a `default` clusterset which is empty but can be used for cluster segregation.  Clustersets can be created to accomodate any number of customer requirements, such as a clusterset based on geographical locations, cluster roles, environment differences, etc.  There is no limit on the number of clustersets an admin can create.  
       * `global`: When specified, the policy applies universally across all managed clusters within the scope of RHACM governance. This setting ensures consistent enforcement of critical policies without the need to specify individual clusters or selectors.

* `matchExpressions`:
  * `key`: Specifies the label key to match against.
  * `operator`: Defines the comparison operation to perform. Common operators include In, NotIn, Exists, and DoesNotExist.
  * `values`: Lists the values that the label key must have for the match to succeed.

For example, the policy above targets clusters labeled with `vendor=OpenShift`. This means the policy will only apply to clusters that have been labeled as being OpenShift vendors, allowing for targeted enforcement based on specific cluster characteristics.


## Summary of Current policies

As of this writing, the policies in place on the Hub cluster are used to:
* configure the ldap oauth and rbac components 
* the groupsync operator installation/groupsync instance creation for admin and appdev teams
* the external dns operator installation.  

The policies can and will change as the needs of the teams evolve over time.   
