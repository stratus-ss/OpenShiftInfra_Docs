# Use of the Argo Applicationset 

## Enhancing Operational Efficiency with Argo ApplicationSets
In our ongoing quest to modernize our IT operations, we've embraced a GitOps methodology, which aligns closely with our goal of achieving seamless, automated deployments. A pivotal component of this approach is Argo CD, a tool that embodies the principles of GitOps for Kubernetes environments. Within our Argo CD setup, we employ an Argo Application Set, specifically named day2-appset, to manage our Day 2 operations with unparalleled efficiency.

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

