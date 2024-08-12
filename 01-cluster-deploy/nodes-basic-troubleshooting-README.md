# Node troubleshooting

## Connecting to OCP nodes for troubleshooting purposes

In preparing for an OCP cluster deployment, a `ssh-key` is specified within the `install-config.yaml`.  During the installation, a copy of the public key is stored in the bootstrap node , and the private cluster nodes. Because you have the corresponding private key, you can access these instances by using SSH. 

An example: ```ssh -i <path to ssh key> core@<ip address of node>```

This method of accessing the nodes is primarily important when troubleshooting a cluster deployment that failed.  One can ssh to the last set of nodes deployed, and troubleshoot by reading logs using the `journalctl` command.  

This ssh method should only be used for troubleshooting purposes.  

Should the ssh keys need to be updated after the cluster has been deployed, you can follow the steps listed here:
https://access.redhat.com/solutions/3868301


