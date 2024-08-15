# Use of the Argo Applicationset 

## Enhancing Operational Efficiency with Argo ApplicationSets
In our ongoing quest to modernize our IT operations, we've embraced a GitOps methodology, which aligns closely with our goal of achieving seamless, automated deployments. A pivotal component of this approach is Argo CD, a tool that embodies the principles of GitOps for Kubernetes environments. Within our Argo CD setup, we employ an Argo Application Set, specifically named day2-appset, to manage our Day 2 operations with unparalleled efficiency.


## Applicationset Overview
Argo ApplicationSets are a powerful feature within Argo CD designed to automate and enhance the management of multiple Argo CD Applications across numerous clusters. It introduces a scalable and efficient method for defining and orchestrating deployments, especially beneficial in complex environments involving many clusters or large monorepos.

### Key Features and Benefits
* Multi-Cluster Support: ApplicationSet automates the creation and management of Argo CD Applications for each targeted cluster, significantly reducing manual efforts and potential errors.
* Monorepo Deployments: Simplifies the deployment of multiple applications contained within a single repository by leveraging templating to dynamically generate Argo CD Applications based on predefined patterns or criteria.
* Self-Service for Unprivileged Users: Facilitates a secure self-service model, allowing developers without direct access to the Argo CD namespace to deploy applications, streamlining operations and enhancing security.
* Templated Automation: Enables automated generation of Argo CD Applications based on templates defined within an ApplicationSet resource, supporting dynamic deployments tailored to various environments or configurations.
### How ApplicationSet Works
The ApplicationSet controller operates alongside Argo CD, typically within the same namespace. It monitors for newly created or updated ApplicationSet Custom Resources (CRs) and automatically constructs corresponding Argo CD Applications according to the specifications defined in these CRs.

### Example ApplicationSet Resource
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

## The Role of day2-appset
The day2-appset plays a critical role in our Argo CD architecture, serving exclusively the ACM (Advanced Cluster Management) hub cluster instance. Its main objective is to facilitate the deployment of Day 2 configurations—configurations that come into play after the initial setup, such as operator installations and application deployments—from a designated Git repository to the most suitable clusters. This process is guided by a strategic placement strategy and employs advanced templating techniques to tailor deployments to each cluster's unique requirements.

## Strategic Placement and Dynamic Templating
Central to the day2-appset is a sophisticated placement strategy that precisely targets which clusters receive the Day 2 configurations. This strategy is informed by labels assigned to each cluster, enabling highly targeted deployments. Furthermore, the day2-appset leverages Go templating to dynamically generate application definitions that are perfectly suited to each cluster's specifics. This templating process draws upon information from both the Git repository and the cluster itself, ensuring that the configurations deployed are optimally adapted to the receiving environment.

A particularly noteworthy aspect of this templating is the conditional logic embedded within the `spec.source.path` field. This logic, using the results of an if/else statement, evaluates the presence of specific labels on the cluster, such as `cluster=default` and `env=<environment>`, to decide from which Git folder to deploy the configurations. This flexibility allows us to tailor deployments to different environments (development, testing, production) or accommodate custom configurations for specific clusters.
Example Usage: ```{{if eq "default" .metadata.labels.cluster }}<folder name>{{ .metadata.labels.env }}/{{index .path.segments 1}}{{else}}{{ .name }}/{{index .path.segments 1}}{{end}}```

## Dynamic Naming and Namespace Selection
Building on the adaptability of our deployments, the day2-appset utilizes Go templating within the `.spec.template` section to dynamically name the Day 2 configurations and select the appropriate namespace for deployment. This process ensures that each deployment is uniquely identified and placed within the correct namespace, streamlining management and monitoring efforts.

## Tailoring Deployments for Custom Clusters
For clusters requiring custom configurations, the day2-appset accommodates by allowing the replication of Day 2 configurations from environment-specific folders to a custom folder. This approach ensures that all necessary components are available in the custom folder, ready for customization as needed.

## Special Handling for Velero and Trident
Certain Day 2 configurations, notably Velero for backup solutions and Trident for storage provisioning, necessitate additional considerations. The day2-appset addresses these needs by incorporating specific parameter definitions within the Helm chart deployments. These parameters dynamically insert the cluster name and other relevant details into the configuration, ensuring that Velero and Trident are correctly configured for each environment.
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


