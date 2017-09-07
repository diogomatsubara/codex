# Part II - Deploying on Azure

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on Microsoft Azure.

## Things You'll Need

 1. Your Azure Subscription ID
 2. Your Azure Client ID
 3. Your Azure Client Secret
 4. Your Azure Tenant ID

 To find these credentials, follow closely the Creating Credentials section here: https://www.terraform.io/docs/providers/azurerm/index.html

 One last thing you'll need:
 5. A name for your Azure Resource Group

## Creating an Azure Cloud via Terraform

 In the terraform/azure directory of this repo, create a file called `azure.tfvars` and enter the above values in the following format:

 ```
 subscription_id = "..."
 client_id = "..."
 client_secret = "..."
 tenant_id = "..."
 resource_group_name = "..."
 ```
 If you need to change the region of your Azure cloud or the network prefix, you can override the defaults by adding:

 ```
 aws_region = "East US"
 network = "10.39"
 ```

 See https://azure.microsoft.com/en-us/regions/ for a list of available Azure regions. 

 As a quick pre-flight check, run `make manifest` to compile your Terraform plan and suss out any issues with naming, missing variables, configuration, etc.:

 ```
 make manifest
 ```

 If everything worked out you should se a summary of the plan.  If this is the first time you've done this, all of your changes should be additions.  

 Now we pull the trigger: 
 ```
 make deploy
 ```

 Terraform will connect to your Azure account and build our bastion host, a NAT box, subnets, and Security Groups. 

### Accessing the bastion host
 
 You now need to find the IP address of your bastion host: </br>
 In your Azure dashboard, click Resource Groups on the left sidebar and then click on your resource group. 
 In the list of resources in this resource group, click `bastionvm`. 
 The IP address will appear under `Public IP address`. 

 The default username for this machine is `ops` and the default password is `c1oudc0w!`

 Access the bastion host using these credentials via `ssh`. 

### Add SSH Keys to bastion Host
TODO
 

### Installing the Necessary Packages on the bastion Host via Jumpbox

````
jump@jumpbox:~$ sudo curl -o /usr/local/bin/jumpbox \
>     https://raw.githubusercontent.com/starkandwayne/jumpbox/master/bin/jumpbox
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  8561  100  8561    0     0  56303      0 --:--:-- --:--:-- --:--:-- 56695
jump@jumpbox:~$ sudo chmod 0755 /usr/local/bin/jumpbox
jump@jumpbox:~$ sudo jumpbox system
                   _.-+.
              _.-""     '.
          +:""            '.
          J \               '.
           L \             _.-+
           |  '.       _.-"   |
           J    \  _.-"       L
            L    +"          J
            +    |           |     (( jumpbox ))
             \   |          .+
              \  |       .-'
               \ |    .-'
                \| .-'
                 +

>> Installing Core System Packages (via apt-get)
Reading package lists... Done
Building dependency tree
Reading state information... Done
tmux is already the newest version.
The following extra packages will be installed:
  git-man liberror-perl
Suggested packages:
  git-daemon-run git-daemon-sysvinit git-doc git-el git-email git-gui gitk
  gitweb git-arch git-bzr git-cvs git-mediawiki git-svn zip
The following NEW packages will be installed:
  git git-man liberror-perl pwgen tree unzip
0 upgraded, 6 newly installed, 0 to remove and 0 not upgraded.
Need to get 3,518 kB of archives.
After this operation, 22.5 MB of additional disk space will be used.
Get:1 http://azure.archive.ubuntu.com/ubuntu/ trusty/main liberror-perl all 0.17-1.1 [21.1 kB]
Get:2 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main git-man all 1:1.9.1-1ubuntu0.3 [699 kB]
Get:3 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main git amd64 1:1.9.1-1ubuntu0.3 [2,586 kB]
Get:4 http://azure.archive.ubuntu.com/ubuntu/ trusty/main pwgen amd64 2.06-1ubuntu4 [17.3 kB]
Get:5 http://azure.archive.ubuntu.com/ubuntu/ trusty/universe tree amd64 1.6.0-1 [37.8 kB]
Get:6 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main unzip amd64 6.0-9ubuntu1.5 [157 kB]
Fetched 3,518 kB in 0s (9,700 kB/s)
Selecting previously unselected package liberror-perl.
(Reading database ... 28424 files and directories currently installed.)
Preparing to unpack .../liberror-perl_0.17-1.1_all.deb ...
Unpacking liberror-perl (0.17-1.1) ...
Selecting previously unselected package git-man.
Preparing to unpack .../git-man_1%3a1.9.1-1ubuntu0.3_all.deb ...
Unpacking git-man (1:1.9.1-1ubuntu0.3) ...
Selecting previously unselected package git.
Preparing to unpack .../git_1%3a1.9.1-1ubuntu0.3_amd64.deb ...
Unpacking git (1:1.9.1-1ubuntu0.3) ...
Selecting previously unselected package pwgen.
Preparing to unpack .../pwgen_2.06-1ubuntu4_amd64.deb ...
Unpacking pwgen (2.06-1ubuntu4) ...
Selecting previously unselected package tree.
Preparing to unpack .../tree_1.6.0-1_amd64.deb ...
Unpacking tree (1.6.0-1) ...
Selecting previously unselected package unzip.
Preparing to unpack .../unzip_6.0-9ubuntu1.5_amd64.deb ...
Unpacking unzip (6.0-9ubuntu1.5) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Processing triggers for mime-support (3.54ubuntu1.1) ...
Setting up liberror-perl (0.17-1.1) ...
Setting up git-man (1:1.9.1-1ubuntu0.3) ...
Setting up git (1:1.9.1-1ubuntu0.3) ...
Setting up pwgen (2.06-1ubuntu4) ...
Setting up tree (1.6.0-1) ...
Setting up unzip (6.0-9ubuntu1.5) ...
>> Checking for jq v1.5
>> Installing jq v1.5
   installed  (jq-1.5)
>> Checking for spruce v1.6.0
>> Installing spruce v1.6.0
   installed  (spruce - Version 1.6.0)
>> Checking for safe v0.0.21
>> Installing safe v0.0.21
   installed  (safe v0.0.21)
>> Checking for vault v0.6.0
>> Installing vault v0.6.0
Archive:  /tmp/vault.zip
  inflating: vault
   installed  (Vault v0.6.0)
>> Checking for bosh-init v0.0.81
>> Installing bosh-init v0.0.81
   installed  (version 0.0.81-775439c-2015-12-09T00:36:03Z)
>> Checking for genesis v1.5.2
>> Installing genesis v1.5.2
   installed  (genesis 1.5.2 (61864a21370c))
sent invalidate(passwd) request, exiting
sent invalidate(group) request, exiting
sent invalidate(group) request, exiting



   ALL DONE
jump@jumpbox:~$
````
