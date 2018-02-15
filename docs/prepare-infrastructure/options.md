# Options

## Choose a Cloud

One of the most powerful features of Cloud Foundry and BOSH is the concept of the Cloud Provider Interface (CPI).  With this abstraction layer, BOSH can deploy the same way to each cloud that has a compatible CPI.

The major clouds we have instructions for in Codex are as follows:

  * [Amazon Web Services]
  * [Google Cloud Platform]
  * [Microsoft Azure]
  * [OpenStack]
  * [VMWare vSphere]

## Public, Private, or On-Premises

AWS, GCP, and Azure, are **infrastructure-as-a-service** providers.  Even though access to these clouds can be fully segmented off into private networks, they are referred to as **public clouds**.

OpenStack and VMWare vSphere are considered **private** or **on-premises** clouds because they are hosted on dedicated hardware in your datacenter.  They work the same with Cloud Foundry, thanks to the CPI abstraction, yet they need to be built, managed, and maintained by your company, rather than an external vendor.

All details that don't refer specifically to the process of building a Cloud Foundry platform on each of these clouds we will refer you to that specific infrastructure vendor.  We will however recommend cloud-specific instructions that provide secure and capable permissions to use with Terraform.

[Amazon Web Services]: https://aws.amazon.com
[Google Cloud Platform]: https://cloud.google.com
[Microsoft Azure]: https://azure.microsoft.com
[OpenStack]: https://www.openstack.org
[VMWare vSphere]: https://www.vmware.com/products/vsphere.html

## Vendor Selected

Got your cloud vendor in mind?  Click on the name of the cloud you're going to use in the left navigation under **Prepare Infrastructure**.  We'll guide you through the specific steps you'll need to take, parameters to gather, and things to be aware of before we start to build your environment.
