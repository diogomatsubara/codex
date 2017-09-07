# Certificate & Key Management in a BOSH World

SSL/TLS Certificates play a prominent role in the configuration
and use of various deployments, and managing them has been a
problematic and error-prone endeavor, in practice.

This document attempts to enumerate where certificates are
necessary, what trust issues arise when the certificates are
self-signed or otherwise unverifiable, and how those issues can be
avoided outright, or mitigated.

For the purposes of illustration, this document assumes that the
client has set aside `example.com` for use in this deployment.

## Services With Certificates

| Service | Sensitive Traffic | Verified? |
| :--- | :--- | :--- |
| BOSH | Security credentials present in deployment manifests | NO |
| Vault | Stores / distributes all security credentials | Yes (skippable) |
| SHIELD | Credentials for target/storage systems | Yes (skippable) |
| Concourse | Credentials used in pipelines; build job output | Yes (skippable) |

Ultimately, we want to be able to utilize valid, signed
certificates for all of these systems, to avoid man-in-the-middle
attacks and shut down spoofing attempts.

## Option 1 - Real Certificates

This is the easiest, most secure option available: talk to a
certificate authority (like Thawte or Verisign) and provision a
new certificate for each service:

* proto-bosh.example.com
* vault.example.com (perhaps with subjectAltNames)
* shield.example.com
* runway.example.com

The certificates and their corresponding private keys can be
stored inside of the Vault and made available to each deployment
via the Spruce `(( vault ... ))` operator.

Since these certificates are signed by a recognized authority,
most operating systems and end user browsers will already be
configured with the signing authorities public certificate,
meaning that they can verify the identity of the remote system by
way of the provided certificate.

## Option 2 - Wildcard Certificates

Depending on the volume of certificates needed, and the domain
name structure of the customer environments, a wildcard
certificate may be more economical.  In this case, a certificate
authority would provide a single certificate good for
`*.example.com`.

This certificate (and its private key) can then be stored in the
Vault and made available to deployments via Spruce.  One drawback
of using wildcard certificates is that everyone shares the private
key.  While this may not pose a problem in highly-controlled
environments, one must be cognizant of who _does_ have access to
the private key.

As with Option 1, the wildcard certificate is signed by a
recognized authority, so most operating systems and web browsers
will trust the certificate without much fuss.

## Option 3 - Certificate Authority

An alternative to paying a certificate authority for certificates
(wildcard or otherwise) is to _become_ a certificate authority and
just issue certificates to yourself free of charge.

The certificate authority could itself be kept in the Vault
(although offline, air-gapped storage may be more secure), and new
certificates issues via the CA as needed (either wildcard or
dedicated).

Unfortunately, our certificate authority is brand new, and no one
trusts it out of the box.

This impacts the user experience greatly.  Anyone trying to access
the SHIELD or Concourse web interfaces will be presented with an
"invalid certificate" warning.  The `vault`, `safe` and `fly`
command-line utilities would need to be instructed to skip
certificate verification.

All of these situations open you up to MitM and spoofing attacks.
The only way to get around these problems is to inject the CA
certificate into the client processes.

The CA certificate needs to be trusted by the following clients:

* The bastion host
* The jump boxes
* All BOSH deployment VMs
* End User Web Browsers
* Concourse worker containers

The bastion host can be manually configured.

The jump boxes will be deployed via BOSH, which has the ability to
provision additional trusted CA certificates on top of the
stemcell.  In a similar vein, boxes deployed by BOSH, across all
of the deployments will have the new CA per the director
configuration.

The remaining two types of clients require some sort of
self-service.  If we run a simple HTTP server to host the
certificate authority certificate, end users can either trust
unverified certificates, or install the certificate authority.

Concourse worker containers can follow a similar path, using the
`genesis` script to download the CA certificate on every run,
before doing any deployments.
