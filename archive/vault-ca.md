## Building with Local Certificate Authority services

We are going to build root and an intermediate certificate
authority services using vault running on the bastion host.

(assumption you are logged onto one of the user bastion accounts)

We do not want to lose our vault information so we are going to using
a file backend.   We are also going to enable memory locking without
vault using root access.

```bash
cd $HOME
sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
mkdir vault
```

Now lets create our vault configuration file before we start up the server.
The secrets we will stored in the ~/vault/secrets directory.

```bash
cat >vault/vault.hcl <<EOF
disable_mlock  = false

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

backend "file" {
  path = "${HOME}/vault/secrets"
}
EOF
```

Now we start up vault using the configuration we just created. I am leaving the vault server in the forground, so we can see any errors that might happen.

```bash
vault server -config=${HOME}/vault/vault.hcl
```

Leave this session open and now open another session to the same user to
carry out the remaining operations.

In the session we will initialize, unseal the vault and authorize.
Remember to save your unseal keys and root token somehow safe.

```bash
export VAULT_ADDR=http://localhost:8200
vault init
# save those keys and root token
vault unseal             # use any key not used before
vault unseal             # ditto
vault unseal             # ditto
vault auth               # use your root token
vault status
```

Now we are going to setup the root CA service and certificate to have a ~ 10 year expiration.
Feel free  read about the pki backend if you want at https://www.vaultproject.io/docs/secrets/pki/ if want to know what that **exclude_cn_from_sans** means.

```bash
vault mount -path=codex-root-ca -description="Codex Root CA" -max-lease-ttl=87648h pki
$ vault mounts
vault write codex-root-ca/root/generate/internal \
common_name="Codex Root Certificate" \
ttl=87648h \
key_bits=4096 \
exclude_cn_from_sans=true
```

We created our certificate. Now read it back and lets setup the internal url
to use this CA service. You will need the internal ip address of the bastion host.

```bash
curl -s http://localhost:8200/v1/codex-root-ca/ca/pem | openssl x509 -text
vault write codex-root-ca/config/urls issuing_certificates="http://10.30.0.211:8200/v1/codex-root-ca"
```

### Build the Operations Intermediate Certificate Authority

We are going to create the operations intermidiate certificate authority with a maximum of time live of approximately 5 years.  The difference will create a key and a certificate signing request (CSR).  Then we will sign CSR using or Root certificate service.  The signed certificate will then be stored in the our operations certificate authority vault

```bash
vault mount -path=codex-ops-ca -description="Codex Operations Intermediate CA" -max-lease-ttl=43800h pki
vault mounts
vault write codex-ops-ca/intermediate/generate/internal \
common_name="Codex Operations Intermediate CA" \
ttl=43800h \
key_bits=4096 \
exclude_cn_from_sans=true
```
Now save the csr request and now get it signed by the root CA service.
Cut and paste the screen copy and remove any noise characters.
vi vault/codex-ops.csr

```bash
vault write codex-root-ca/root/sign-intermediate \
csr=@vault/codex-ops.csr \
common_name="Codex Ops Intermediate CA" \
ttl=43800h
```

Now save the signed certifcate.
Cut and paste the screen copy of the first certificate and remove any noise characters.

```bash
vi vault/codex-ops.crt

vault write codex-ops-ca/intermediate/set-signed \
certificate=@vault/codex-ops.crt

curl -s http://localhost:8200/v1/codex-ops-ca/ca/pem | openssl x509 -text | head -20

vault write codex-ops-ca/config/urls \
issuing_certificates="http://10.30.0.211:8200/v1/codex-ops-ca/ca" \
crl_distribution_points="http://10.30.0.211:8200/v1/codex-ops-ca/crl"
```

## Defining Certificate Generation Policies  (Roles)

Now we define types of cerficates we want to issue.  A policy defines
properties for the certificate that will be generated.
Vaults calls these policies roles.

Here are the various properites as defined in Vault version 0.6.0.

|Property|Notes|Description|
|--------|-----|-----------|
|ttl|optional| The Time To Live value provided as a string duration with time suffix. Hour is the largest suffix. If not set, uses the system default value or the value of max_ttl, whichever is shorter.|
|max_ttl|optional| The maximum Time To Live provided as a string duration with time suffix. Hour is the largest suffix. If not set, defaults to the system maximum lease TTL.|
|allow_localhost|optional| If set, clients can request certificates for localhost as one of the requested common names. This is useful for testing and to allow clients on a single host to talk securely. Defaults to true.|
|allowed_domains|optional<br/>See footnote 1| Designates the domains of the role, provided as a comma-separated list. This is used with the allow_bare_domains and allow_subdomains options. There is no default.|
|allow_bare_domains|optional| If set, clients can request certificates matching the value of the actual domains themselves; e.g. if a configured domain set with allowed_domains is example.com, this allows clients to actually request a certificate containing the name example.com as one of the DNS values on the final certificate. In some scenarios, this can be considered a security risk. Defaults to false.|
|allow_subdomains|optional<br>See footnote 1| If set, clients can request certificates with CNs that are subdomains of the CNs allowed by the other role options. This includes wildcard subdomains. For example, an allowed_domains value of example.com with this option set to true will allow foo.example.com and bar.example.com as well as *.example.com. This is redundant when using the allow_any_name option. Defaults to false.|
|allow_any_name|optional<br/>See footnote 1| If set, clients can request any CN. Useful in some circumstances, but make sure you understand whether it is appropriate for your installation before enabling it. Defaults to false.|
|enforce_hostnames|optional| If set, only valid host names are allowed for CNs, DNS SANs, and the host part of email addresses. Defaults to true.|
|allow_ip_sans|optional| If set, clients can request IP Subject Alternative Names. No authorization checking is performed except to verify that the given values are valid IP addresses. Defaults to true.|
|server_flag|optional<br/>See footnote 2| If set, certificates are flagged for server use. Defaults to true.|
|client_flag|optional<br/>See footnote 2| If set, certificates are flagged for client use. Defaults to true.|
|code_signing_flag|optional<br/>See footnote 2| If set, certificates are flagged for code signing use. Defaults to false.|
|email_protection_flag|optional| If set, certificates are flagged for email protection use. Defaults to false.|
|key_type|optional| The type of key to generate for generated private keys. Currently, rsa and ec are supported. Defaults to rsa.|
|key_bits|optional| The number of bits to use for the generated keys. Defaults to 2048; this will need to be changed for ec keys. See https://golang.org/pkg/crypto/elliptic/#Curve for an overview of allowed bit lengths for ec.|
|use_csr_common_name|optional| If set, when used with the CSR signing endpoint, the common name in the CSR will be used instead of taken from the JSON data. This does not include any requested SANs in the CSR. Defaults to false.|

1. The properties allowed_domains, allow_subdomains, and allow_any_name can combine together.
2. The properties server_flag, client_flag, and code_signing_flag are also combined together as well.


Create a dummy one year (including leap day) policy nameed one-year-policy.
```bash
vault write codex-ops-ca/roles/one-year-policy \
key_bits=2048 \
max_ttl=8784h \
allow_any_name=true
```

## Issuing Certificates

create a dummy certificate for a 6 month time to live

```bash
vault write codex-ops-ca/issue/one-year-policy \
common_name="dummy-name" \
ip_sans="10.30.1.5" \
ttl=4392h
format=pem
```
