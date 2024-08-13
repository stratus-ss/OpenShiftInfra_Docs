# Argo Appset

The `day2-appset` file is used to apply to the ACM hub cluster argo instance.  This appset uses the `matrix-generators` option to merge to child generators, the `git` generator and the `clusters` generator to allow the ability to use the go-templating feature to pull the necessary information from both git and clusters variables.

The primary purpose of this appset is to deploy the day2 configs from the git repo and apply them to the correct clusters based on a label placed on the cluster.  Particularly, this line in the `spec.source.path` uses the if/else statement to determine which git folder it should deploy from:
```{{if eq "default" .metadata.labels.cluster }}<folder name>{{ .metadata.labels.env }}/{{index .path.segments 1}}{{else}}{{ .name }}/{{index .path.segments 1}}{{end}}```

The above is looking for 2 labels of `cluster=default` and `env=<environment>` (this could be dev, test, or prd) on the cluster and will deploy from the `<folder>-<env>` folder.  Should the label `cluster=default` not exist, then the day2 configs will be installed from a folder named after the cluster.  The folders in the git repo would look something like this:
```day2-dev day2-test day2-prd <custom cluster name>```

By using the if/else statment in the appset, it gives a little more flexibility in how the day 2 configs are deployed based on labels on the clusters.

> [!NOTE]
> Since the appset is using an if/else statement, it will either deploy from one of the <env> folders or the custom folder.  Therefore, if you have a custom cluster, you'll need to cp -r everything from an day2-<env> folder and paste it in the custom folder.  This means you will have all the day2 components in this custom folder just as you would the day2-<env> folder.  Then, for custom clusters, you will edit the day2 componenet in its folder as needed. 

Argo will utilize the appset's gotemplating to name the day2 config, pick the cluster, and the namespace to deploy the cluster in by using this in the `.spec.template` section of the appset: `'{{index .path.segments 1}}'` and the `{{.name}}`
This path.segments is looking at the git path and determining which folder the day2 config resides in, and the .name is pulling that cluster name from the `clusters` generator to populate the cluster name in certain fields.  

The clusters generator pulls this info from the cluster secrets that live in the `openshift-gitops` namespace.

> [!NOTE]
> Two of the day2 configs, Velero and Trident, require that the deployment process utilizes some form of label and/or cluster name to determine the naming strategy of those componenents within the cluster.  This is being done by the appset's parameter definition, located under the `template` block of the appset config.

```      source:
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
            value: '{{ .metadata.labels.netappLIF }}'```

The appset looks at the values.yaml file of the day2 components and makes the necessary changes.
