Amazon Web Services Guide
=========================

Pre-requisites
--------------

1. Create an Amazon Web Services account.
2. We'll need credentials, such as ``aws_secret_key`` and ``aws_secret_key``.
3. A local computer running terraform_.

.. _terraform: https://www.terraform.io/downloads.html

Terraform
---------

Config and Run
~~~~~~~~~~~~~~

1. Clone the codex repository. ``git clone https://github.com/starkandwayne/codex-v2.git``
2. From the root of the **codex** folder, cd to ``terraform/aws``.
3. Make a copy of the example file.

::

	cp aws.tfvars.example aws.tfvars


4. Open ``aws.tfvars`` in an editor and fill in the required variables at the top.

5. From your terminal, run ``make all``.

Output
~~~~~~

Once the Terraform plan has run, it will yield a private network with a public-ip
address to the bastion host we will use to setup the rest of our systems.

In the last few lines of output look for this:

::

	box.bastion.public = 35.53.126.226

Jumpbox
-------

We use a tool called Jumpbox_ to help setup the bastion host.

.. _jumpbox: https://github.com/starkandwayne/jumpbox

The user for the bastion is ``ubuntu``, so with the key-pair we used with Terraform
and the IP address from the end of the Terraform output, we can build the ssh
connection string.

Let's connect to the bastion.

::

	ssh -i /path/to/key-pair.pem ubuntu@35.166.126.226
