## Custom Routes

### OpenShift Console

In order to customize the route for the OpenShift web console you will need to have a DNS entry present if the console URL will not be part of the wild card DNS entry. Additionally, if the domain suffix is being changed or you simply want to have a specific SSL certificate for the web UI, additional work is required.

#### Custom Certificates

By default, any secret referenced by the ingress controller needs to be created in the **openshift-config** namespace. In case this is missing from your cluster you can create this with the following command:

```
oc create namespace openshift-config
```


> [!NOTE]
> Normally you should be using `oc new-project`, however creation of some projects are restricted by the OpenShift API (such as any project starting with `openshift-`).
> Using `oc create namespace` uses the kubernetes primitives and gets around these restrictions. USE WITH CAUTION!

To create the secret use the following command template:

```
oc create secret tls <secret name> --cert=path/to/tls.crt --key=path/to/tls.key -n openshift-config
```

#### Editing The Ingress Controller

You can edit the ingress controller with the following command:

```
oc edit ingress.config.openshift.io cluster
```

You can edit the `spec` section so it looks like this:

```
spec:
  componentRoutes:
    - name: console
      namespace: openshift-console
      hostname: <hostname> 
      servingCertKeyPairSecret:
        name: <secret_name> 
```

Saving and exiting the editor will cause some pods to restart. The console will be unavailable until the pods have finished their restart procedures.