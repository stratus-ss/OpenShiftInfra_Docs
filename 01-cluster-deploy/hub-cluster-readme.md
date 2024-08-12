## Cluster deploy playbook

This playbook is used to deploy an Openshift cluster to the vmware environment.  All variables the template uses are stored in the 'cluster-vars.yaml' file.  

The playbook creates the install-config.yaml from a jinja template stored under /templates and run the openshift-install command using that install-config.yaml.  

This will create a directory under /opt/OCP with the name of the cluster being built.  


example usage:
`ansible-playbook -i inventory/ install-ipi.yaml --extra-vars="@cluster-vars.yaml"`

should you need to destroy a cluster for any reason, you can run the following:

`openshift-install destroy cluster --dir /opt/OCP/<name of cluster>  --log-level error`


## Prereqs to be in place prior to running the deployment playbook

* oc cli and openshift installer binaries installed on bastion linux server (note: the version of the binaries installed will determine the version of the openshift cluster to be deployed.)
* ansible installed on bastion node
* api/ingress dns entries created and resolvable
* networks carved out for ocp clusters (usually /24) (make sure the bastion server can "see" those network)
* OpenShift Container Platform installer requires access to port 443 on the vCenter and ESXi hosts. You verified that port 443 is accessible.
* validate service account permissions being used to create these things in vcenter
* need to create ssh key for the install-config.yaml to utilize from the bastion, preferably a key from a shared user on the bastion as opposed to a single user.  
* grab the certificate from the vcenter ui and put on the bastion host. can use wget and put them in /tmp.
  use this wget command: `get https://<vcenter_hostname>/certs/download.zip --no-check-certificate`
  now unzip download.zip and combine the lin certs: `cat certs/lin/*.0 > ca.yaml; cp certs/lin/* /etc/pki/ca-trust/source/anchors; update-ca-trust extract`
