# Overview

We use a colorful diagram to show the architecture of the CF ecosystem as below.

![Levels of Bosh][levels-of-bosh]

In the above diagram, BOSH (1) is the **proto-BOSH** (we will explain why we need it soon)
, while BOSH (2) and BOSH (3) are the per-site BOSH Directors.

Before we deploy anything in the above diagram, this guide will walk you though
how to prepare the underlying cloud infrastructure and a bastion host using Terraform.

From the bastion, we setup a special BOSH Director we call the
**proto-BOSH** server where software like Vault, Concourse, Prometheus and
SHIELD are setup in order to give each of the environments created after
the **proto-BOSH** key benefits of:

-  Secure Credential Storage and Rotation
-  Pipeline Management
-  Monitoring Framework
-  Backup and Restore Datastores

Once the **proto-BOSH** environment is setup, the child environments
will have the added benefit of being able to update their BOSH software
as a release, rather than having to re-initialize with ``bosh-init``.

This also increases the resiliency of all BOSH Directors through
monitoring and backups with software created by Stark & Wayne's
engineers.

And visibility into the progress and health of each application,
release, or package is available through the power of Concourse
pipelines.

[levels-of-bosh]: /images/levels_of_bosh.png
