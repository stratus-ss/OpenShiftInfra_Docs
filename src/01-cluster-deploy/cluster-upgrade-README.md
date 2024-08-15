# Cluster Upgrade Overview
Upgrading an OpenShift cluster, especially those managed by Red Hat Advanced Cluster Management (RHACM), involves several methods tailored to different environments and requirements. These methods leverage RHACM's capabilities to manage and monitor clusters efficiently, ensuring a smooth upgrade process. Here's an overview of the available methods:

## Upgrading from RHACM UI 

For clusters that are connected to the internet, RHACM simplifies the upgrade process by identifying available updates and notifying administrators through the console. The steps to upgrade a cluster in a connected environment are as follows:

1. **Check for Available Updates**: RHACM automatically identifies updates for managed clusters and notifies administrators via the console.
2. **Initiate Upgrade**: Navigate to the RHACM console, select "Automate infrastructure" > "Clusters", find the cluster you wish to upgrade, and select "Upgrade cluster". Choose the target version for the upgrade and confirm the action.

## Upgrading from CLI
To upgrade an OpenShift cluster from the command-line interface (CLI), you'll follow a series of steps that involve checking the current cluster status, reviewing available updates, and initiating the upgrade process. Here's a step-by-step guide based on the provided sources:

### Prerequisites

Before starting the upgrade process, ensure you have the following:

- Install the OpenShift CLI (`oc`) that matches the version for your updated version.
- Log in to the cluster as a user with `cluster-admin` privileges.
- Install the `jq` package on your local machine for JSON processing.

### Procedure

1. **Check Cluster Availability**

   First, verify that your cluster is available and check its current version:

   ```bash
   oc get clusterversion
   ```

   Example output:

   ```
   NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
   version   4.8.13     True        False         158m    Cluster version is 4.8.13
   ```

2. **Review Current Update Channel Information**

   Confirm that your channel is set correctly. For production clusters, you must subscribe to a `stable-*`, `eus-*`, or `fast-*` channel.

   ```bash
   oc get clusterversion -o json | jq ".items[1].spec"
   ```

   Example output:

   ```
   {
     "channel": "stable-4.9",
     "clusterID": "990f7ab8-109b-4c95-8480-2bd1deec55ff"
   }
   ```

3. **View Available Updates**

   Use the `oc adm upgrade` command to view the available updates and note the version number of the update you want to apply:

   ```bash
   oc adm upgrade
   ```

   Example output listing available updates:

   ```
   Cluster version is 4.13.0-0.okd-2023-10-28-065448
   Upstream: https://amd64.origin.releases.ci.openshift.org/graph
   Channel: stable-4
   Recommended updates:
     VERSION                        IMAGE
     4.14.0-0.okd-2024-01-06-084517 registry.ci.openshift.org/origin/release@sha256:c4a6b6850701202f629c0e451de784b02f0de079650a1b9ccbf610448ebc9227
   ```

4. **Initiate the Upgrade Process**

   After selecting the desired update version, you can initiate the upgrade process. The exact command to start the upgrade varies depending on the specific version and update channel you're moving to. Typically, you would use a command similar to:

   ```bash
   oc adm upgrade --to=<target-version>
   ```

   Replace `<target-version>` with the version number you noted earlier.

### Important Notes

- Review the OpenShift documentation and release notes for any special considerations or steps specific to the version you're upgrading to.
- Monitor the upgrade process closely to address any issues that arise during the upgrade.



For more detailed guidance on upgrading your cluster, please refer to the [official documentation](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.8/html/manage_cluster/upgrading-your-cluster).

