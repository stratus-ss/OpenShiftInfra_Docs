# Automating Spoke Cluster Deployment with RHACM in VMware

## Introduction

This project focuses on automating the generation of manifests used by Hive in Red Hat Advanced Cluster Management for Kubernetes (RHACM) to orchestrate the creation of clusters. Specifically, it targets the deployment of spoke clusters within a VMware environment, leveraging RHACM's capabilities for multicluster management.

## Technical Overview of Spoke Clusters in RHACM

A spoke cluster, from the perspective of Red Hat Advanced Cluster Management, is a Kubernetes cluster managed and monitored by a central hub cluster via the Multicluster Manager (MCMM). The MCMM serves as the orchestrator, overseeing the lifecycle of these spoke clusters across various environments, including VMware. This architecture enables centralized management, monitoring, and policy enforcement across multiple clusters, thereby enhancing security, compliance, and operational efficiency.

## Role Structure for Managed Clusters

The project utilizes an Ansible role structure specifically designed for creating and managing clusters within RHACM. This structure includes:

- **Roles Directory**: Contains the `managed-clusters-role`, encapsulating the logic for deploying and managing clusters.
- **Templates**: Features Jinja2 templates for generating various Kubernetes manifest files essential for cluster setup, such as `managedcluster.yaml.j2`, `klusterletaddonconfig.yaml.j2`, and others.
- **Variables Files**: Located under `roles/managed-clusters-role/defaults/main`, these files define critical parameters for cluster deployment, including network configurations, image sets, and authentication details.

## Important Variables Files

- **vsphere-vars.yml**: Specifies common variables applicable to all clusters, such as the base domain, network CIDRs, and the network type.
- **vsphere-secret-vars.yml**: Contains sensitive variables not intended for public visibility, including trust bundles, SSH keys, and credentials for VM deployments.

### Security Note

Variables files that contain secrets, particularly those ending with `_secret`, must be encrypted using Ansible Vault if they are stored in publicly accessible source control management (SCM) systems. This measure ensures the confidentiality of sensitive information.

## Deployment Steps

1. **Validation**: Ensure all variables in the configuration files are correctly set.
2. **Login to Hub Cluster**: Authenticate to the RHACM hub cluster CLI using `oc login`.
3. **Execute Playbook**: Run the Ansible playbook with the inventory file to initiate the cluster deployment process.

This structured approach aligns with the RHACM cluster lifecycle management, facilitating efficient and secure deployment of spoke clusters within VMware environments.

