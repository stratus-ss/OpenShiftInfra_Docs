# Leveraging cert-manager in OpenShift Clusters via Helm Chart

Cert-manager is an open-source native Kubernetes certificate management controller that automates the management and issuance of TLS certificates from various sources, including Let’s Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self-signed. It is particularly crucial in OpenShift clusters, given the dynamic nature of containerized applications that necessitate secure communication channels.

## Importance of cert-manager

In cloud-native architectures, services often communicate over HTTPS to ensure data privacy and integrity. Manual management of TLS certificates in such environments can be cumbersome and error-prone. Cert-manager automates this process, significantly reducing operational overhead and minimizing security risks associated with expired or misconfigured certificates.

- **Automated Certificate Lifecycle Management**: Cert-manager automatically renews certificates before they expire, ensuring uninterrupted service availability.
- **Integration with Multiple Certificate Authorities (CAs)**: It supports various certificate authorities, allowing organizations to choose the CA that best fits their compliance and security requirements.
- **Native Kubernetes Integration**: Being a native Kubernetes controller, cert-manager seamlessly integrates with Kubernetes resources and workflows, simplifying deployment and management.
- **Security Compliance**: Automated certificate management helps maintain security posture and compliance with industry standards by ensuring valid and up-to-date certificates.

## How cert-manager Works

Cert-manager operates by watching events from the Kubernetes API server and responding to challenges from certificate authorities (CAs) to prove ownership of domain names. It consists of several components:

- **cert-manager Controller**: Manages Certificate resources and ensures they are issued and renewed.
- **Webhook Solver**: Handles ACME (Automatic Certificate Management Environment) challenges for domain validation.
- **CA Injector**: Injects CA certificates into Kubernetes Secrets for use by other components.


The workflow typically involves creating a `Certificate` and an `Issuer` resource. In the context of certificate issuance, there is something called the DNS-01 challenge which is used by Automatic Certificate Management Environments to prove domain authorities. The challenge works like this:


* Challenge Initiation: When requesting a certificate, Cert Manager communicates with the CA to initiate a DNS-01 challenge for the domain(s) in question.
* Token Generation: The CA provides a unique token for the challenge.
* TXT Record Creation: The ACME client then creates a DNS TXT record for the domain, embedding the token in a specific format. This record is typically placed under a subdomain like _acme-challenge.YOURDOMAIN.COM.
* Verification: The CA queries the DNS system for the TXT record. If the record exists and contains the expected token, the CA verifies domain ownership and proceeds with the issuance of the certificate.


In the example below, the Issuer is contacting Let's Encrypt:

```
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: example-rfc2136-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: example-rfc2136-account-key
    solvers:
    - dns01:
        rfc2136:
          nameserver: YOUR_DNS_SERVER_IP:53
          tsigKeyName: YOUR_TSIG_KEY_NAME
          tsigAlgorithm: HMACSHA512
          tsigSecretSecretRef:
            name: YOUR_K8S_SECRET_HOLDING_TSIG_KEY
            key: YOUR_KEY_INSIDE_THE_SECRET
```

In the above configuration here is an explanation of the options under `rfc2136`

**nameserver**: The IP address and port of your DNS server that supports RFC2136. This is where cert-manager will send DNS updates.

**tsigKeyName**: The name of the TSIG key used for authentication with the DNS server. This key is generated separately and must match the key name used in your DNS server configuration.

**tsigAlgorithm**: The algorithm used for the TSIG key. This must match the algorithm chosen when generating the TSIG key. Common algorithms include HMACSHA256, HMACSHA384, and HMACSHA512.

**tsigSecretSecretRef**: A reference to an OpenShift Secret that holds the TSIG key. This secret should contain the TSIG key in plain text. The name is the name of the secret, and the key is the key inside the secret that contains the TSIG key value.


After specifying the `Issuer` you can then create a `Certificate` resource in order to generate a valid TLS certificate. An example of a certificate definition might look like:

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-application-certificate
  namespace: default
spec:
  secretName: my-application-tls
  dnsNames:
  - myapp.example.com
  - www.myapp.example.com
  issuerRef:
    name: example-rfc2136-issuer
    kind: Issuer
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days before expiration
```

The final step is to link your deployment to the `Certificate` created above:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-application-deployment
spec:
  template:
    spec:
      containers:
      - name: my-application-container
        image: my-application-image
        ports:
        - containerPort: 443
        volumeMounts:
        - name: tls
          mountPath: "/etc/tls"
          readOnly: true
      volumes:
      - name: tls
        secret:
          secretName: my-application-tls
```

> [!IMPORTANT]
> The key here is that the `secretName` in the deployment needs to match the `name` of the `Certificate` generated above. 
> You can also customize where the certificates are stored in the container by changing the `mountPath` section in the `Deployment`.

## Deployment via Argo CD Using Helm Chart

In the current environment, OpenShift clusters managed through Advanced Cluster Management (ACM) and Argo CD, cert-manager is deployed using its Helm chart. This approach leverages the power of Helm, a package manager for Kubernetes, to simplify the deployment and management of cert-manager. The deployment is orchestrated by Argo CD, which utilizes an ApplicationSet to manage deployments across multiple clusters or environments.

The use of the Helm chart for cert-manager deployment is facilitated by enabling the `enable-helm` flag in the ApplicationSet definition within Argo CD. This flag instructs Argo CD to treat the specified source as a Helm chart, allowing for the seamless integration of Helm-based applications into the GitOps workflow.

Deploying cert-manager via Argo CD using Helm charts offers several benefits:

- **Version Control**: Changes to cert-manager configurations are tracked in version control, enabling audit trails and rollback capabilities.
- **Automated Updates**: Argo CD can automatically apply updates to cert-manager, ensuring that the latest features and security patches are applied without manual intervention.
- **Consistency Across Environments**: By defining cert-manager configurations in Git, organizations can easily replicate consistent setups across multiple environments, such as staging, testing, and production.

This method of deploying cert-manager exemplifies the synergy between GitOps practices, Helm charts, and automated certificate management in achieving robust, secure, and efficient cloud-native environments. It streamlines certificate management, enhances security posture, and reduces operational complexity, making it an essential component in modern Kubernetes-based infrastructures.

