#
# Amazonia - Terraform Configuration for
# Azure Bosh + Cloud Foundry
#
#

variable "azure_region"     { default = "West US" } # Azure Region (https://azure.microsoft.com/en-us/regions/)
variable "network"        { default = "10.4" }      # First 2 octets of your /16

variable "resource_group_name" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "prefix" { default="codex"}

##############################################################

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

#############################################################

# Create a resource group
resource "azurerm_resource_group" "default" {
    name     = "${var.resource_group_name}"
    location = "${var.azure_region}"
}

#############################################################

resource "azurerm_virtual_network" "default" {
    name = "${var.prefix}_virtual_network"
    address_space = ["${var.network}.0.0/16"]
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"
}

#############################################################


########   #######  ##     ## ######## #### ##    ##  ######
##     ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
##     ## ##     ## ##     ##    ##     ##  ####  ## ##
########  ##     ## ##     ##    ##     ##  ## ## ## ##   ####
##   ##   ##     ## ##     ##    ##     ##  ##  #### ##    ##
##    ##  ##     ## ##     ##    ##     ##  ##   ### ##    ##
##     ##  #######   #######     ##    #### ##    ##  ######

resource "azurerm_route_table" "external" {
    name = "${var.resource_group_name}-external"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"

    route {
        name = "internet"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "internet"
    }
}

resource "azurerm_route_table" "internal" {
    name = "${var.resource_group_name}-internal"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"

    route {
        name = "internal"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "VnetLocal"
    }

}


 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone for NAT box ONLY

resource "azurerm_subnet" "dmz" {
    name = "${var.resource_group_name}-dmz"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.0.0/24"
    route_table_id = "${azurerm_route_table.internal.id}"
}
output "azure.network.dmz.subnet" {
  value = "${azurerm_subnet.dmz.id}"
}


###############################################################
# GLOBAL - Global Infrastructure
#
# This includes the following:
#   - proto-BOSH
#   - SHIELD
#   - Vault (for deployment credentials)
#   - Concourse (for deployment automation)
#   - Bolo
#

resource "azurerm_subnet" "global-infra-0" {
    name = "global-infra-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.1.0/24"
    route_table_id = "${azurerm_route_table.internal.id}"
}
output "azure.network.global-infra-0.subnet" {
  value = "${azurerm_subnet.global-infra-0.id}"
}

resource "azurerm_subnet" "global-infra-1" {
    name = "global-infra-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.2.0/24"
    route_table_id = "${azurerm_route_table.internal.id}"
}
output "azure.network.global-infra-1.subnet" {
  value = "${azurerm_subnet.global-infra-1.id}"
}

resource "azurerm_subnet" "global-infra-2" {
    name = "global-infra-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.3.0/24"
    route_table_id = "${azurerm_route_table.internal.id}"
}
output "azure.network.global-infra-2.subnet" {
  value = "${azurerm_subnet.global-infra-2.id}"
}

resource "azurerm_subnet" "global-openvpn-0" {
    name = "global-openvpn-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.4.0/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.global-openvpn-0.subnet" {
  value = "${azurerm_subnet.global-openvpn-0.id}"
}

resource "azurerm_subnet" "global-openvpn-1" {
    name = "global-openvpn-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.4.128/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.global-openvpn-1.subnet" {
  value = "${azurerm_subnet.global-openvpn-1.id}"
}





###############################################################
# DEV-INFRA - Development Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#

resource "azurerm_subnet" "dev-infra-0" {
    name = "dev-infra-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.16.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-infra-0.subnet" {
  value = "${azurerm_subnet.dev-infra-0.id}"
}

resource "azurerm_subnet" "dev-infra-1" {
    name = "dev-infra-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.17.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-infra-1.subnet" {
  value = "${azurerm_subnet.dev-infra-1.id}"
}

resource "azurerm_subnet" "dev-infra-2" {
    name = "dev-infra-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.18.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-infra-2.subnet" {
  value = "${azurerm_subnet.dev-infra-2.id}"
}


###############################################################
# DEV-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#

resource "azurerm_subnet" "dev-cf-edge-0" {
    name = "dev-cf-edge-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.19.0/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-edge-0.subnet" {
  value = "${azurerm_subnet.dev-cf-edge-0.id}"
}

resource "azurerm_subnet" "dev-cf-edge-1" {
    name = "dev-cf-edge-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.19.128/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-edge-1.subnet" {
  value = "${azurerm_subnet.dev-cf-edge-1.id}"
}


###############################################################
# DEV-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#

resource "azurerm_subnet" "dev-cf-core-0" {
    name = "dev-cf-core-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.20.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-core-0.subnet" {
  value = "${azurerm_subnet.dev-cf-core-0.id}"
}

resource "azurerm_subnet" "dev-cf-core-1" {
    name = "dev-cf-core-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.21.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-core-1.subnet" {
  value = "${azurerm_subnet.dev-cf-core-1.id}"
}

resource "azurerm_subnet" "dev-cf-core-2" {
    name = "dev-cf-core-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.22.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-core-2.subnet" {
  value = "${azurerm_subnet.dev-cf-core-2.id}"
}


###############################################################
# DEV-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "azurerm_subnet" "dev-cf-runtime-0" {
    name = "dev-cf-runtime-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.23.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-runtime-0.subnet" {
  value = "${azurerm_subnet.dev-cf-runtime-0.id}"
}

resource "azurerm_subnet" "dev-cf-runtime-1" {
    name = "dev-cf-runtime-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.24.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-runtime-1.subnet" {
  value = "${azurerm_subnet.dev-cf-runtime-1.id}"
}

resource "azurerm_subnet" "dev-cf-runtime-2" {
    name = "dev-cf-runtime-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.25.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-runtime-2.subnet" {
  value = "${azurerm_subnet.dev-cf-runtime-2.id}"
}

###############################################################
# DEV-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#

resource "azurerm_subnet" "dev-cf-svc-0" {
    name = "dev-cf-svc-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.26.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-svc-0.subnet" {
  value = "${azurerm_subnet.dev-cf-svc-0.id}"
}

resource "azurerm_subnet" "dev-cf-svc-1" {
    name = "dev-cf-svc-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.27.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-svc-1.subnet" {
  value = "${azurerm_subnet.dev-cf-svc-1.id}"
}

resource "azurerm_subnet" "dev-cf-svc-2" {
    name = "dev-cf-svc-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.28.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-svc-2.subnet" {
  value = "${azurerm_subnet.dev-cf-svc-2.id}"
}


###############################################################
# DEV-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#

resource "azurerm_subnet" "dev-cf-db-1" {
    name = "dev-cf-db-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.29.16/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-db-1.subnet" {
  value = "${azurerm_subnet.dev-cf-db-1.id}"
}

resource "azurerm_subnet" "dev-cf-db-2" {
    name = "dev-cf-db-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.29.32/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.dev-cf-db-2.subnet" {
  value = "${azurerm_subnet.dev-cf-db-2.id}"
}



###############################################################
# STAGING-INFRA - Staging Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#

resource "azurerm_subnet" "staging-infra-0" {
    name = "staging-infra-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.32.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-infra-0.subnet" {
  value = "${azurerm_subnet.staging-infra-0.id}"
}

resource "azurerm_subnet" "staging-infra-1" {
    name = "staging-infra-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.33.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-infra-1.subnet" {
  value = "${azurerm_subnet.staging-infra-1.id}"
}

resource "azurerm_subnet" "staging-infra-2" {
    name = "staging-infra-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.34.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-infra-2.subnet" {
  value = "${azurerm_subnet.staging-infra-2.id}"
}




###############################################################
# STAGING-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#

resource "azurerm_subnet" "staging-cf-edge-0" {
    name = "staging-cf-edge-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.35.0/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-edge-0.subnet" {
  value = "${azurerm_subnet.staging-cf-edge-0.id}"
}

resource "azurerm_subnet" "staging-cf-edge-1" {
    name = "staging-cf-edge-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.35.128/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-edge-1.subnet" {
  value = "${azurerm_subnet.staging-cf-edge-1.id}"
}




###############################################################
# STAGING-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#

resource "azurerm_subnet" "staging-cf-core-0" {
    name = "staging-cf-core-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.36.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-core-0.subnet" {
  value = "${azurerm_subnet.staging-cf-core-0.id}"
}
resource "azurerm_subnet" "staging-cf-core-1" {
    name = "staging-cf-core-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.37.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-core-1.subnet" {
  value = "${azurerm_subnet.staging-cf-core-1.id}"
}

resource "azurerm_subnet" "staging-cf-core-2" {
    name = "staging-cf-core-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.38.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-core-2.subnet" {
  value = "${azurerm_subnet.staging-cf-core-2.id}"
}

###############################################################
# STAGING-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#

resource "azurerm_subnet" "staging-cf-runtime-0" {
    name = "staging-cf-runtime-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.39.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-runtime-0.subnet" {
    value = "${azurerm_subnet.staging-cf-runtime-0.id}"
}

resource "azurerm_subnet" "staging-cf-runtime-1" {
    name = "staging-cf-runtime-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.40.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-runtime-1.subnet" {
    value = "${azurerm_subnet.staging-cf-runtime-1.id}"
}

resource "azurerm_subnet" "staging-cf-runtime-2" {
    name = "staging-cf-runtime-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.41.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-runtime-2.subnet" {
    value = "${azurerm_subnet.staging-cf-runtime-2.id}"
}


###############################################################
# STAGING-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#

resource "azurerm_subnet" "staging-cf-svc-0" {
    name = "staging-cf-svc-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.42.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-svc-0.subnet" {
    value = "${azurerm_subnet.staging-cf-svc-0.id}"
}

resource "azurerm_subnet" "staging-cf-svc-1" {
    name = "staging-cf-svc-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.43.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-svc-1.subnet" {
    value = "${azurerm_subnet.staging-cf-svc-1.id}"
}

resource "azurerm_subnet" "staging-cf-svc-2" {
    name = "staging-cf-svc-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.44.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-svc-2.subnet" {
    value = "${azurerm_subnet.staging-cf-svc-2.id}"
}

###############################################################
# STAGING-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#

resource "azurerm_subnet" "staging-cf-db-0" {
    name = "staging-cf-db-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.45.0/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-db-0.subnet" {
  value = "${azurerm_subnet.staging-cf-db-0.id}"
}

resource "azurerm_subnet" "staging-cf-db-1" {
    name = "staging-cf-db-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.45.16/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-db-1.subnet" {
  value = "${azurerm_subnet.staging-cf-db-1.id}"
}

resource "azurerm_subnet" "staging-cf-db-2" {
    name = "staging-cf-db-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.45.32/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.staging-cf-db-2.subnet" {
  value = "${azurerm_subnet.staging-cf-db-2.id}"
}

###############################################################
# PROD-INFRA - Production Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#

resource "azurerm_subnet" "prod-infra-0" {
    name = "prod-infra-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.48.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-infra-0.subnet" {
  value = "${azurerm_subnet.prod-infra-0.id}"
}

resource "azurerm_subnet" "prod-infra-1" {
    name = "prod-infra-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.49.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-infra-1.subnet" {
  value = "${azurerm_subnet.prod-infra-1.id}"
}

resource "azurerm_subnet" "prod-infra-2" {
    name = "prod-infra-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.50.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-infra-2.subnet" {
  value = "${azurerm_subnet.prod-infra-2.id}"
}

###############################################################
# PROD-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#

resource "azurerm_subnet" "prod-cf-edge-0" {
    name = "prod-cf-edge-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.51.0/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-edge-0.subnet" {
  value = "${azurerm_subnet.prod-cf-edge-0.id}"
}

resource "azurerm_subnet" "prod-cf-edge-1" {
    name = "prod-cf-edge-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.51.128/25"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-edge-1.subnet" {
  value = "${azurerm_subnet.prod-cf-edge-1.id}"
}


###############################################################
# PROD-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#

resource "azurerm_subnet" "prod-cf-core-0" {
    name = "prod-cf-core-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.52.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-core-0.subnet" {
  value = "${azurerm_subnet.prod-cf-core-0.id}"
}

resource "azurerm_subnet" "prod-cf-core-1" {
    name = "prod-cf-core-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.53.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-core-1.subnet" {
  value = "${azurerm_subnet.prod-cf-core-1.id}"
}

resource "azurerm_subnet" "prod-cf-core-2" {
    name = "prod-cf-core-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.54.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-core-2.subnet" {
  value = "${azurerm_subnet.prod-cf-core-2.id}"
}


###############################################################
# PROD-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#

resource "azurerm_subnet" "prod-cf-runtime-0" {
    name = "prod-cf-runtime-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.55.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-runtime-0.subnet" {
  value = "${azurerm_subnet.prod-cf-runtime-0.id}"
}

resource "azurerm_subnet" "prod-cf-runtime-1" {
    name = "prod-cf-runtime-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.56.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-runtime-1.subnet" {
  value = "${azurerm_subnet.prod-cf-runtime-1.id}"
}

resource "azurerm_subnet" "prod-cf-runtime-2" {
    name = "prod-cf-runtime-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.57.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-runtime-2.subnet" {
  value = "${azurerm_subnet.prod-cf-runtime-2.id}"
}



###############################################################
# PROD-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#

resource "azurerm_subnet" "prod-cf-svc-0" {
    name = "prod-cf-svc-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.58.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-svc-0.subnet" {
  value = "${azurerm_subnet.prod-cf-svc-0.id}"
}

resource "azurerm_subnet" "prod-cf-svc-1" {
    name = "prod-cf-svc-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.59.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-svc-1.subnet" {
  value = "${azurerm_subnet.prod-cf-svc-1.id}"
}

resource "azurerm_subnet" "prod-cf-svc-2" {
    name = "prod-cf-svc-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.60.0/24"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-svc-2.subnet" {
  value = "${azurerm_subnet.prod-cf-svc-2.id}"
}

###############################################################
# PROD-CF-DB - Cloud Foundry Databases
#
#  These subnets house the internal Cloud Foundry
#  databases (either MySQL release or RDS DBs).
#

resource "azurerm_subnet" "prod-cf-db-0" {
    name = "prod-cf-db-0"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.61.0/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-db-0.subnet" {
  value = "${azurerm_subnet.prod-cf-db-0.id}"
}

resource "azurerm_subnet" "prod-cf-db-1" {
    name = "prod-cf-db-1"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.61.16/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-db-1.subnet" {
  value = "${azurerm_subnet.prod-cf-db-1.id}"
}

resource "azurerm_subnet" "prod-cf-db-2" {
    name = "prod-cf-db-2"
    resource_group_name = "${azurerm_resource_group.default.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix = "${var.network}.61.32/28"
    route_table_id = "${azurerm_route_table.external.id}"
}
output "azure.network.prod-cf-db-2.subnet" {
  value = "${azurerm_subnet.prod-cf-db-2.id}"
}


##    ##    ###     ######  ##        ######
###   ##   ## ##   ##    ## ##       ##    ##
####  ##  ##   ##  ##       ##       ##
## ## ## ##     ## ##       ##        ######
##  #### ######### ##       ##             ##
##   ### ##     ## ##    ## ##       ##    ##
##    ## ##     ##  ######  ########  ######




  #### ##    ##  ######   ########  ########  ######   ######
   ##  ###   ## ##    ##  ##     ## ##       ##    ## ##    ##
   ##  ####  ## ##        ##     ## ##       ##       ##
   ##  ## ## ## ##   #### ########  ######    ######   ######
   ##  ##  #### ##    ##  ##   ##   ##             ##       ##
   ##  ##   ### ##    ##  ##    ##  ##       ##    ## ##    ##
  #### ##    ##  ######   ##     ## ########  ######   ######


  # OTHER RULES NEEDED:
  #  - BOSH (for proto-BOSH to deploy BOSH directors)
  #  - SHIELD (for backups to/from infranet)
  #  - Bolo (to submit monitoring egress to infranet)
  #  - Concourse (either direct acccess to BOSH, or worker communication)
  #  - Vault (jumpboxen need to get to Vault for creds.  also, concourse workers)

  # All other traffic is blocked by an implicit
  # Block all other traffic.



  ########  ######   ########  ########  ######   ######
  ##       ##    ##  ##     ## ##       ##    ## ##    ##
  ##       ##        ##     ## ##       ##       ##
  ######   ##   #### ########  ######    ######   ######
  ##       ##    ##  ##   ##   ##             ##       ##
  ##       ##    ##  ##    ##  ##       ##    ## ##    ##
  ########  ######   ##     ## ########  ######   ######



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######





##    ##    ###    ########
###   ##   ## ##      ##
####  ##  ##   ##     ##
## ## ## ##     ##    ##
##  #### #########    ##
##   ### ##     ##    ##
##    ## ##     ##    ##

resource "azurerm_public_ip" "natip" {
    name = "natip"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"
    public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "nat" {
    name = "natNetworkInterface"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"

    ip_configuration {
        name = "nat_ip"
        subnet_id = "${azurerm_subnet.dmz.id}"
        private_ip_address_allocation = "dynamic"
	public_ip_address_id = "${azurerm_public_ip.natip.id}"
    }

}

resource "azurerm_storage_account" "nat" {
    name = "${var.prefix}nataccount"
    resource_group_name = "${azurerm_resource_group.default.name}"
    location = "${var.azure_region}"
    account_type = "Standard_LRS"
}

resource "azurerm_storage_container" "nat" {
    name = "${var.prefix}natcontainer"
    resource_group_name = "${azurerm_resource_group.default.name}"
    storage_account_name = "${azurerm_storage_account.nat.name}"
    container_access_type = "private"
}



resource "azurerm_virtual_machine" "nat" {

    name = "natvm"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"
    network_interface_ids = ["${azurerm_network_interface.nat.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "14.04.2-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "myosdisk1"
        vhd_uri = "${azurerm_storage_account.nat.primary_blob_endpoint}${azurerm_storage_container.nat.name}/myosdisk1.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "nat"
        admin_username = "ops"
        admin_password = "c1oudc0w!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags {
        environment = "staging"
    }

}




########     ###     ######  ######## ####  #######  ##    ##
##     ##   ## ##   ##    ##    ##     ##  ##     ## ###   ##
##     ##  ##   ##  ##          ##     ##  ##     ## ####  ##
########  ##     ##  ######     ##     ##  ##     ## ## ## ##
##     ## #########       ##    ##     ##  ##     ## ##  ####
##     ## ##     ## ##    ##    ##     ##  ##     ## ##   ###
########  ##     ##  ######     ##    ####  #######  ##    ##

resource "azurerm_public_ip" "bastionip" {
    name = "bastionip"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"
    public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "bastion" {
    name = "bastionNetworkInterface"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"

    ip_configuration {
        name = "bastion_ip"
        subnet_id = "${azurerm_subnet.dmz.id}"
        private_ip_address_allocation = "dynamic"
	public_ip_address_id = "${azurerm_public_ip.bastionip.id}"
    }

}

resource "azurerm_storage_account" "bastion" {
    name = "${var.prefix}bastionaccount"
    resource_group_name = "${azurerm_resource_group.default.name}"
    location = "${var.azure_region}"
    account_type = "Standard_LRS"
}

resource "azurerm_storage_container" "bastion" {
    name = "${var.prefix}bastioncontainer"
    resource_group_name = "${azurerm_resource_group.default.name}"
    storage_account_name = "${azurerm_storage_account.bastion.name}"
    container_access_type = "private"
}



resource "azurerm_virtual_machine" "bastion" {

    name = "bastionvm"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.default.name}"
    network_interface_ids = ["${azurerm_network_interface.bastion.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "14.04.2-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "myosdisk1"
        vhd_uri = "${azurerm_storage_account.bastion.primary_blob_endpoint}${azurerm_storage_container.bastion.name}/myosdisk1.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "bastion"
        admin_username = "ops"
        admin_password = "c1oudc0w!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags {
        environment = "staging"
    }

}