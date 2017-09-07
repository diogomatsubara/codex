# Secure Your Secrets with Vault

## Best Practices

* One Vault or One Vault Per Environment

This may not be possible because of security requirement preconditions or
network topology.  In these cases place the additional Vault deployments as
high as possible in the environment structure.

* Be consistent with a descriptive, reusable and unique path

For example here's the path to the BOSH admin password:

```
$ safe get secret/aws/proto/bosh/users/admin
```

* Keep related data together

```
$ safe set secret/aws access_key secret_key
```

[top](vault.md#secure-your-secrets-with-vault)

## High Availability

Vault provides an active/passive [high availability(HA)][ha] service using
shared storage across the nodes. Vault recommends using Consul to provide its
HA capability.

The passive nodes will forward all requests to the active node. This means Vault
 ports need to be open via TCP.  The default Vault port is 8200.

>It is important to note that only **unsealed** servers act as a standby. If a
server is still in the sealed state, then it cannot act as a standby as it would
 be unable to serve any requests should the active server fail.

All Vaults nodes need to be running the same version since we do not know if there
are storage structure changes.  The [upgrade path][upgrade] could be tricky
since Vault does not support zero downtime deployments.

> Please note that Vault **does not support** true zero-downtime upgrades, but
with proper upgrade procedure the downtime should be very short (a few hundred
milliseconds to a second depending on how the speed of access to the storage
backend).

### Storage Backends

HA Storage Backends | Supported By
------------------- | -------------
             consul | Hashicorp
               etcd | Community
          zookeeper | Community
           dynamodb | Community

The following storage backends exist for Vault, but do not have a HA option:

  * S3
  * Azure
  * Swift
  * Mysql
  * Postgresql
  * Inmem
  * file

[top](vault.md#secure-your-secrets-with-vault)

## Unsealing a High Availability Vault

This example will show a three node cluster being unsealed incrementally and
the resulting status output at each stage.

Here's what we have to begin with:

```
$ safe targets

 proda  https://10.30.1.16:8200
 prodb  https://10.30.2.16:8200
 prodc  https://10.30.3.16:8200
 proto  http://127.0.0.1:8200
```

Let's target the first server:

```
$ export VAULT_SKIP_VERIFY=1
$ safe target proda
Now targeting proda at https://10.30.1.16:8200

$ safe vault status
Error checking seal status: Error making API request.

Key 1: 04f3bf668a9e9741d14afe03666cef4ad778382a44b21200b0e721bd2c78c18a01

URL: GET https://10.30.1.16:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized
!! exit status 1
```

The initialize command will generate a master key for the Vault that we'll use
to unseal the Vault.

```
$ safe vault init
Key 1: 04f3bf668a9e9741d14afe03666cef4ad778382a44b21200b0e721bd2c78c18a01
Key 2: a5cab4dc25f25eb8b0ef6d12ca4799f1b9b75d4b2029999596d2ca3757f80dfa02
Key 3: 2db8d11844e6668dcb9e3bd3ba96c931f838ce4866e408d6109d07ce1ddc7d4003
Key 4: 569da0c75c216459035086464545ddd14a785d66c8a23baf87e10afca692b91d04
Key 5: deefc5033d355c6c7821d08735948d110bf7ce658e6faaec01aec705ecb6c9a705
Initial Root Token: eb4e2ab1-fd69-324b-8c68-6bd8524d3df0

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your Vault will remain permanently sealed.
```

Vault uses [Shamir's Secret Sharing][shamir] algorithm to split and recreate a
master key.  Once enough shards of the key are given, the master key will unseal
 the Vault.

If the keys are lost and the Vault needs to be re initialized all previous
secrets and encrypted data is lost.

We've already got our first node in our sights with `proda` targeted... Time to
 crack the Vault.

```
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1      <- keep an eye on progress

$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2      <- watch the progress

$ safe vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0      <- 0 progress is unsealed

$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: active
    Leader: https://10.30.1.16:8200
```

We can see that our `proda` is the leader, it's active and it's got HA enabled.
  What happens though when we look at the next node?

```
$ safe target prodb
Now targeting prodb at https://10.30.2.16:8200

$ safe vault status
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: sealed
!! exit status 2
```

So HA is enabled but it's sealed! Can we fix it? YES WE CAN!

```
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1

$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2

$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: https://10.30.1.16:8200
```

And now `prodb` is part of the HA cluster **and** it's in standby.  We'll move
on to `prodc`, next.

```
$ safe target prodc
Now targeting prodc at https://10.30.3.16:8200

$ safe vault status
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: sealed
!! exit status 2
```

FINISH HIM!

```
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1

$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2

$ safe vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: https://10.30.3.16:8200
```

All nodes are either active or standby and unsealed.

[top](vault.md#secure-your-secrets-with-vault)

## Migrating Keys

If you were going to migrate from `proto` to `proda` Vault, you'd begin by
targeting the `proto` vault.

```
$ safe target proto
Now targeting proto at https://127.0.0.1:8200
```

And then export the secrets to a file:

```
$ safe export secret >proto.secrets
```

Target the destination Vault, like `proda`.

```
$ safe target proda
Now targeting proda at https://10.30.1.16:8200
```
Now Authenticate using the Token from the `init` above

```
$ safe auth token
Authenticating against proda at https://10.30.1.16:8200
Token:
$
```

Import the secrets into the Vault.

```
$ safe import <proto.secrets
wrote secret/aws/proto/bosh/blobstore/director
wrote secret/aws/proto/bosh/nats
wrote secret/aws/proto/bosh/users/admin
wrote secret/handshake
wrote secret/aws/proto/bosh/blobstore/agent
wrote secret/aws/proto/bosh/db
wrote secret/aws/proto/bosh/users/hm
wrote secret/aws/proto/bosh/vcap
wrote secret/aws/proto/shield/keys/core
```

And finally you can test that the `proda` received the imported values by
viewing database.

```
$ safe tree
.
└── secret
    ├── aws/
    │   └── proto/
    │       ├── bosh/
    │       │   ├── blobstore/
    │       │   │   ├── agent
    │       │   │   └── director
    │       │   ├── db
    │       │   ├── nats
    │       │   ├── users/
    │       │   │   ├── admin
    │       │   │   └── hm
    │       │   └── vcap
    │       └── shield/
    │           └── keys/
    │               └── core
    └── handshake
```

[top](vault.md#secure-your-secrets-with-vault)

[ha]:      https://www.vaultproject.io/docs/internals/high-availability.html
[upgrade]: https://www.vaultproject.io/docs/install/upgrade.html
[shamir]:  https://www.vaultproject.io/docs/concepts/seal.html
