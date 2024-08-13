## MetalLB

### Helm Chart Version

In some cases it may be desirable to forgo the Operator install from Operator Hub and install MetalLB directly from the upstream Helm chart. This approach provides maximal flexibility and may integrate with existing workflows around Helm Chart deployments.

In order to get a local copy of the Helm Chart, you can add the repo to your cluster:

```
helm repo add metallb https://metallb.github.io/metallb
```

Next, you can use the `helm pull` command to grab the tarball for local editing or storage:

```
helm pull metallb/metallb
```

Untar the tarball:

```
tar xvf metallb-*.tar
```

The main advantage to this approach instead of installing it directly into the cluster with a `helm install` command is that you can customize the Helm Chart and extend it if needed. You will also have a point of reference for any automation (such as ArgoCD) that you may implement.

With that in mind, the Helm Chart can be installed with the default `values.yaml` file (without modification) that ships with the tarball:

```
helm install metallb metallb/metallb -f values.yaml 
```

> [!NOTE]
> When installing to a project in OpenShift _other_ than `default` there are additional permissions which MetalLB requires.
> The Helm Chart creates the `metallb-speaker` and `metallb-controller` accounts which need elevated privileges which can be added with the following commands:
> ```
> oc adm policy add-scc-to-user anyuid -z metallb-speaker
> oc adm policy add-scc-to-user privileged -n metallb -z metallb-speaker
> oc adm policy add-scc-to-user privileged -n metallb -z metallb-controller 
> ```
> Use these commands with caution as they allow extra privileges that the OpenShift security model normally restricts!

Future enhancements to the above process could include
* Editing the Helm Chart to adjust for permissions without running additional commands
* Setting a default project such as `openshift-metallb` to allow for consistant installations

### Configuration

After the Helm Chart is installed, MetalLB needs to be configured. The pods will deploy without configuration, however VMs or Pods will not receive IPs until MetalLB is properly configured.

The first step is to create an `L2Advertisment`. This file can be used for [advanced configuration](https://metallb.universe.tf/configuration/_advanced_l2_configuration/) including such things as determinging which IP AddressPools to use and which nodes will be available.

A basic L2Adverisement looks like this:

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: <unique name>
  namespace: <namespace of metallb>
```

See the above documentation for more indepth options.

Similarly, the `IPAddressPool` defines either address ranges or network CIDRs. You can see more details [here](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/). A basic example can be seen below:

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: <pool name>
  namespace: <metallb namespace>
spec:
  addresses:
  - 192.168.94.40-192.168.94.70
```

The final step is to tell OpenShift services to use MetalLB.  [The official documentation](https://docs.openshift.com/container-platform/4.15/networking/metallb/metallb-configure-services.html#metallb-configure-services) provides various scenarios that you might consider. A basic example that will accept any IP Address from MetalLB would look like this:

```
apiVersion: v1
kind: Service
metadata:
  name: <service_name>
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  type: LoadBalancer
```

This service will then expose the port `8080` over the IP address which it receives from MetalLB.