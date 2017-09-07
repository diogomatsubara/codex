## Troubleshooting Guide

Here we will display all common errors, the common paths that you ended up in
that position, and the ways to get around them. If you can't find the solution
in the main docs, then the answer will probably be here....ONWARDS!

## Bastion Host

### Missing Commands

If you can't find the `vault` or `genesis` commands, chances are you did not run
the `jumpbox` script, refer to [the Prepare Bastion Host section][1] and make
sure that you remain logged in as the user you creaded with `jumpbox`.  

### proto-BOSH & Shield

Error Deploying **proto-BOSH** with Shield Agent Job.

If you see the error below, then you are running the scripts and everything from
the bastion user, you MUST use the `jumpbox` scripts/users/Vault in order for it
to be nice and not throw errors at you.

```
    Command 'deploy' failed:
      Deploying:
        Building state for instance 'bosh/0':
          Rendering job templates for instance 'bosh/0':
            Rendering templates for job 'shield-agent/38e11abc09d09a2af3572c070cc9813ab640e8dd':
              Rendering template src: config/target.json.erb, dst: config/target.json:
                Rendering template src: /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb, dst: /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/rendered-jobs598042080/config/target.json:
                  Running ruby to render templates:
                    Running command: 'ruby /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-context.json /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/rendered-jobs598042080/config/target.json', stdout: '', stderr: '/home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:189:in `rescue in render': Error filling in template '/home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/bosh-init-release368081404/extracted_jobs/shield-agent/templates/config/target.json.erb' for shield-agent/0 (line 2: #<TypeError: nil is not a symbol nor a string>) (RuntimeError)
        from /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:175:in `render'
        from /home/ubuntu/.bosh_init/installations/bea9b166-9d73-41bc-43b1-37f49aa20d83/tmp/erb-renderer386521023/erb-render.rb:200:in `<main>'
    ':
                      exit status 1
    Makefile:25: recipe for target 'deploy' failed
```

### Terraform

When trying to `make all` to deploy the bastion host. Terraform will connect to
AWS, using your **Access Key ID** and **Secret Key ID**, then spin up all the
things it needs.  When it finishes, you should be left with a bunch of subnets,
configured network ACLs, security groups, routing tables, a NAT instance (for
public internet connectivity) and a bastion host.

If the `deploy` or `all` step fails with errors like:

```
* aws_subnet.prod-cf-edge-0: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1e, us-east-1b, us-east-1d. status code: 400, request id: 8ddbe059-0818-48c2-a936-b551cd76cdeb
* aws_subnet.prod-infra-0: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e. status code: 400, request id: 876f72b2-6bda-4499-98c3-502d213635eb
* aws_subnet.dev-infra-2: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e. status code: 400, request id: 66fafa81-7718-46eb-a606-e4b98e3267b9
```

You can run `make destroy` to clean up, then add a line like `aws_az1 = "d"` to
replace the restricted zone.

### Verify Keypair

There are two ways to check the SSH Key Pair. Either in the AWS Web Console or
with the AWS CLI.

* Check the Fingerprint here on the AWS Web Console [key page][amazon-keys].

* Use AWC CLI, ensure parameters like `--region`, `--key-name` (referring to SSH
key pair) are correct:

```
$ aws ec2 describe-key-pairs --region us-east-1 --key-name bosh|JSON.sh -b| grep 'KeyFingerprint'|awk '{ print $2 }' -
"05:ad:67:04:2a:62:e3:fb:e6:0a:61:fb:13:c7:6e:1b"
```

Once you have the SSH Key Pair fingerprint from AWS, you can then use `openssl`to
[verify the fingerprint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#verify-key-pair-fingerprints)
of your local `*.pem` SSH key pair file.

```
$ openssl pkcs8 -in path_to_private_key -inform PEM -outform DER -topk8 -nocrypt | openssl sha1 -c
(stdin)= 05:ad:67:04:2a:62:e3:fb:e6:0a:61:fb:13:c7:6e:1b
```

## Update TOC

When I try to run `.bin/update_doc` to update the Table of Contents, I got the
following error:

```
==> Pouring node-6.5.0.el_capitan.bottle.tar.gz
Error: The `brew link` step did not complete successfully
The formula built, but is not symlinked into /usr/local
Could not symlink bin/node
Target /usr/local/bin/node
already exists. You may want to remove it:
  rm '/usr/local/bin/node'

To force the link and overwrite all conflicting files:
  brew link --overwrite node

To list all files that would be deleted:
  brew link --overwrite --dry-run node
```

When you do `brew link --overwrite node`, if it fails to due to some file
permissions, then read the output.  Some can be:

  * `sudo chmod 777 /usr/local/share/systemtap/tapset/`
  * `sudo chmod 777 /usr/local/share/doc/node/`

Another good idea is to run `brew doctor` for any other advice that **brew** may
have to make sure the system is running smoothly.

[1]:            https://github.com/starkandwayne/codex/blob/master/aws.md#prepare-bastion-host
[amazon-keys]:  https://console.aws.amazon.com/ec2/v2/home?#KeyPairs:sort=keyName
