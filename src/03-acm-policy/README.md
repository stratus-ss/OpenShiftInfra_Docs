# Advanced Cluster Management (ACM) Policies

Within the realm of Advanced Cluster Management (ACM), policies serve as a cornerstone for enforcing governance and compliance across managed clusters. This directory is dedicated to housing the policies that are operational within the ACM cluster, specifically targeting the `open-cluster-management-hub` namespace for uniformity and ease of management.

## Namespace Consideration

It is imperative to note that the `open-cluster-management-hub` namespace does not exist by default upon ACM installation. Consequently, one of the preliminary steps following ACM configuration involves the explicit creation of this namespace, underscoring its significance in the policy management landscape.

## Policy Framework

The foundational structure of an ACM policy is meticulously crafted to ensure comprehensive coverage and flexibility in governance. Here is an illustrative example of a policy skeleton:


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

## Current policies

As of this writing, the policies in place on the Hub cluster are used to:
* configure the ldap oauth and rbac components 
* the groupsync operator installation/groupsync instance creation for admin and appdev teams
* the external dns operator installation.  

The policies can and will change as the needs of the teams evolve over time.   
