#
# Amazonia - Terraform Configuration for
# GCP BOSH + Cloud Foundry
#

variable "google_project"      {} # Your Google Project Id  (required)
variable "google_network_name" {} # Name of the Network     (required)
#variable "google_credentials"  {} # Credential file path    
variable "google_region"       {} # Google Region           (required)
variable "google_zone_1"       {} # Google Zone 1           (required)
variable "google_zone_2"       {} # Google Zone 2           (required)
variable "google_zone_3"       {} # Google Zone 3           (required)

variable "network"              { default = "10.4" }          # First 2 octets of your /16
variable "bastion_machine_type" { default = "n1-standard-1" } # Bastion Machine Type

variable "google_lb_dev_enabled"     { default = 0 } # Set to 1 to create the DEV LB
variable "google_lb_staging_enabled" { default = 0 } # Set to 1 to create the STAGING LB
variable "google_lb_prod_enabled"    { default = 0 } # Set to 1 to create the PROD LB

###############################################################

provider "google" {
#  credentials = "${file("${var.google_credentials}")}"
  project = "${var.google_project}"
  region  = "${var.google_region}"
}



##    ## ######## ######## ##      ##  #######  ########  ##    ##  ######
###   ## ##          ##    ##  ##  ## ##     ## ##     ## ##   ##  ##    ##
####  ## ##          ##    ##  ##  ## ##     ## ##     ## ##  ##   ##
## ## ## ######      ##    ##  ##  ## ##     ## ########  #####     ######
##  #### ##          ##    ##  ##  ## ##     ## ##   ##   ##  ##         ##
##   ### ##          ##    ##  ##  ## ##     ## ##    ##  ##   ##  ##    ##
##    ## ########    ##     ###  ###   #######  ##     ## ##    ##  ######

###########################################################################
# Default Network
#

resource "google_compute_network" "default" {
  name = "${var.google_network_name}"
}
output "google.network.name" {
  value = "${google_compute_network.default.name}"
}



 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone
#
resource "google_compute_subnetwork" "dmz" {
  name          = "${var.google_network_name}-dmz"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "${var.network}.0.0/24"
  region        = "${var.google_region}"

}
output "google.subnetwork.dmz.name" {
  value = "${google_compute_subnetwork.dmz.name}"
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
resource "google_compute_subnetwork" "global-infra-0" {
  name          = "${var.google_network_name}-global-infra-0"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "${var.network}.1.0/24"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-infra-0.name" {
  value = "${google_compute_subnetwork.global-infra-0.name}"
}
resource "google_compute_subnetwork" "global-infra-1" {
  name          = "${var.google_network_name}-global-infra-1"
  ip_cidr_range = "${var.network}.2.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-infra-1.name" {
  value = "${google_compute_subnetwork.global-infra-1.name}"
}
resource "google_compute_subnetwork" "global-infra-2" {
  name          = "${var.google_network_name}-global-infra-2"
  ip_cidr_range = "${var.network}.3.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-infra-2.name" {
  value = "${google_compute_subnetwork.global-infra-2.name}"
}

###############################################################
# OpenVPN - OpenVPN
#
resource "google_compute_subnetwork" "global-openvpn-0" {
  name          = "${var.google_network_name}-global-openvpn-0"
  ip_cidr_range = "${var.network}.4.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-openvpn-0.name" {
  value = "${google_compute_subnetwork.global-openvpn-0.name}"
}
resource "google_compute_subnetwork" "global-openvpn-1" {
  name          = "${var.google_network_name}-global-openvpn-1"
  ip_cidr_range = "${var.network}.4.128/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-openvpn-1.name" {
  value = "${google_compute_subnetwork.global-openvpn-1.name}"
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
resource "google_compute_subnetwork" "dev-infra-0" {
  name          = "${var.google_network_name}-dev-infra-0"
  ip_cidr_range = "${var.network}.16.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-infra-0.name" {
  value = "${google_compute_subnetwork.dev-infra-0.name}"
}
resource "google_compute_subnetwork" "dev-infra-1" {
  name          = "${var.google_network_name}-dev-infra-1"
  ip_cidr_range = "${var.network}.17.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-infra-1.name" {
  value = "${google_compute_subnetwork.dev-infra-1.name}"
}
resource "google_compute_subnetwork" "dev-infra-2" {
  name          = "${var.google_network_name}-dev-infra-2"
  ip_cidr_range = "${var.network}.18.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-infra-2.name" {
  value = "${google_compute_subnetwork.dev-infra-2.name}"
}

###############################################################
# DEV-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "dev-cf-edge-0" {
  name          = "${var.google_network_name}-dev-cf-edge-0"
  ip_cidr_range = "${var.network}.19.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-edge-0.name" {
  value = "${google_compute_subnetwork.dev-cf-edge-0.name}"
}
resource "google_compute_subnetwork" "dev-cf-edge-1" {
  name          = "${var.google_network_name}-dev-cf-edge-1"
  ip_cidr_range = "${var.network}.19.128/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-edge-1.name" {
  value = "${google_compute_subnetwork.dev-cf-edge-1.name}"
}

###############################################################
# DEV-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "dev-cf-core-0" {
  name          = "${var.google_network_name}-dev-cf-core-0"
  ip_cidr_range = "${var.network}.20.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-core-0.name" {
  value = "${google_compute_subnetwork.dev-cf-core-0.name}"
}
resource "google_compute_subnetwork" "dev-cf-core-1" {
  name          = "${var.google_network_name}-dev-cf-core-1"
  ip_cidr_range = "${var.network}.21.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-core-1.name" {
  value = "${google_compute_subnetwork.dev-cf-core-1.name}"
}
resource "google_compute_subnetwork" "dev-cf-core-2" {
  name          = "${var.google_network_name}-dev-cf-core-2"
  ip_cidr_range = "${var.network}.22.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-core-2.name" {
  value = "${google_compute_subnetwork.dev-cf-core-2.name}"
}

###############################################################
# DEV-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "dev-cf-runtime-0" {
  name          = "${var.google_network_name}-dev-cf-runtime-0"
  ip_cidr_range = "${var.network}.23.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-runtime-0.name" {
  value = "${google_compute_subnetwork.dev-cf-runtime-0.name}"
}
resource "google_compute_subnetwork" "dev-cf-runtime-1" {
  name          = "${var.google_network_name}-dev-cf-runtime-1"
  ip_cidr_range = "${var.network}.24.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-runtime-1.name" {
  value = "${google_compute_subnetwork.dev-cf-runtime-1.name}"
}
resource "google_compute_subnetwork" "dev-cf-runtime-2" {
  name          = "${var.google_network_name}-dev-cf-runtime-2"
  ip_cidr_range = "${var.network}.25.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-runtime-2.name" {
  value = "${google_compute_subnetwork.dev-cf-runtime-2.name}"
}

###############################################################
# DEV-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "dev-cf-svc-0" {
  name          = "${var.google_network_name}-dev-cf-svc-0"
  ip_cidr_range = "${var.network}.26.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-svc-0.name" {
  value = "${google_compute_subnetwork.dev-cf-svc-0.name}"
}
resource "google_compute_subnetwork" "dev-cf-svc-1" {
  name          = "${var.google_network_name}-dev-cf-svc-1"
  ip_cidr_range = "${var.network}.27.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-svc-1.name" {
  value = "${google_compute_subnetwork.dev-cf-svc-1.name}"
}
resource "google_compute_subnetwork" "dev-cf-svc-2" {
  name          = "${var.google_network_name}-dev-cf-svc-2"
  ip_cidr_range = "${var.network}.28.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-svc-2.name" {
  value = "${google_compute_subnetwork.dev-cf-svc-2.name}"
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
resource "google_compute_subnetwork" "staging-infra-0" {
  name          = "${var.google_network_name}-staging-infra-0"
  ip_cidr_range = "${var.network}.32.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-infra-0.name" {
  value = "${google_compute_subnetwork.staging-infra-0.name}"
}
resource "google_compute_subnetwork" "staging-infra-1" {
  name          = "${var.google_network_name}-staging-infra-1"
  ip_cidr_range = "${var.network}.33.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-infra-1.name" {
  value = "${google_compute_subnetwork.staging-infra-1.name}"
}
resource "google_compute_subnetwork" "staging-infra-2" {
  name          = "${var.google_network_name}-staging-infra-2"
  ip_cidr_range = "${var.network}.34.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-infra-2.name" {
  value = "${google_compute_subnetwork.staging-infra-2.name}"
}

###############################################################
# STAGING-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "staging-cf-edge-0" {
  name          = "${var.google_network_name}-staging-cf-edge-0"
  ip_cidr_range = "${var.network}.35.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-edge-0.name" {
  value = "${google_compute_subnetwork.staging-cf-edge-0.name}"
}
resource "google_compute_subnetwork" "staging-cf-edge-1" {
  name          = "${var.google_network_name}-staging-cf-edge-1"
  ip_cidr_range = "${var.network}.35.128/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-edge-1.name" {
  value = "${google_compute_subnetwork.staging-cf-edge-1.name}"
}

###############################################################
# STAGING-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "staging-cf-core-0" {
  name          = "${var.google_network_name}-staging-cf-core-0"
  ip_cidr_range = "${var.network}.36.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-core-0.name" {
  value = "${google_compute_subnetwork.staging-cf-core-0.name}"
}
resource "google_compute_subnetwork" "staging-cf-core-1" {
  name          = "${var.google_network_name}-staging-cf-core-1"
  ip_cidr_range = "${var.network}.37.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-core-1.name" {
  value = "${google_compute_subnetwork.staging-cf-core-1.name}"
}
resource "google_compute_subnetwork" "staging-cf-core-2" {
  name          = "${var.google_network_name}-staging-cf-core-2"
  ip_cidr_range = "${var.network}.38.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-core-2.name" {
  value = "${google_compute_subnetwork.staging-cf-core-2.name}"
}

###############################################################
# STAGING-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "staging-cf-runtime-0" {
  name          = "${var.google_network_name}-staging-cf-runtime-0"
  ip_cidr_range = "${var.network}.39.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-runtime-0.name" {
  value = "${google_compute_subnetwork.staging-cf-runtime-0.name}"
}
resource "google_compute_subnetwork" "staging-cf-runtime-1" {
  name          = "${var.google_network_name}-staging-cf-runtime-1"
  ip_cidr_range = "${var.network}.40.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-runtime-1.name" {
  value = "${google_compute_subnetwork.staging-cf-runtime-1.name}"
}
resource "google_compute_subnetwork" "staging-cf-runtime-2" {
  name          = "${var.google_network_name}-staging-cf-runtime-2"
  ip_cidr_range = "${var.network}.41.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-runtime-2.name" {
  value = "${google_compute_subnetwork.staging-cf-runtime-2.name}"
}

###############################################################
# STAGING-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "staging-cf-svc-0" {
  name          = "${var.google_network_name}-staging-cf-svc-0"
  ip_cidr_range = "${var.network}.42.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-svc-0.name" {
  value = "${google_compute_subnetwork.staging-cf-svc-0.name}"
}
resource "google_compute_subnetwork" "staging-cf-svc-1" {
  name          = "${var.google_network_name}-staging-cf-svc-1"
  ip_cidr_range = "${var.network}.43.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-svc-1.name" {
  value = "${google_compute_subnetwork.staging-cf-svc-1.name}"
}
resource "google_compute_subnetwork" "staging-cf-svc-2" {
  name          = "${var.google_network_name}-staging-cf-svc-2"
  ip_cidr_range = "${var.network}.44.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-svc-2.name" {
  value = "${google_compute_subnetwork.staging-cf-svc-2.name}"
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
resource "google_compute_subnetwork" "prod-infra-0" {
  name          = "${var.google_network_name}-prod-infra-0"
  ip_cidr_range = "${var.network}.48.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-infra-0.name" {
  value = "${google_compute_subnetwork.prod-infra-0.name}"
}
resource "google_compute_subnetwork" "prod-infra-1" {
  name          = "${var.google_network_name}-prod-infra-1"
  ip_cidr_range = "${var.network}.49.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-infra-1.name" {
  value = "${google_compute_subnetwork.prod-infra-1.name}"
}
resource "google_compute_subnetwork" "prod-infra-2" {
  name          = "${var.google_network_name}-prod-infra-2"
  ip_cidr_range = "${var.network}.50.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-infra-2.name" {
  value = "${google_compute_subnetwork.prod-infra-2.name}"
}

###############################################################
# PROD-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "prod-cf-edge-0" {
  name          = "${var.google_network_name}-prod-cf-edge-0"
  ip_cidr_range = "${var.network}.51.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-edge-0.name" {
  value = "${google_compute_subnetwork.prod-cf-edge-0.name}"
}
resource "google_compute_subnetwork" "prod-cf-edge-1" {
  name          = "${var.google_network_name}-prod-cf-edge-1"
  ip_cidr_range = "${var.network}.51.128/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-edge-1.name" {
  value = "${google_compute_subnetwork.prod-cf-edge-1.name}"
}

###############################################################
# PROD-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "prod-cf-core-0" {
  name          = "${var.google_network_name}-prod-cf-core-0"
  ip_cidr_range = "${var.network}.52.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-core-0.name" {
  value = "${google_compute_subnetwork.prod-cf-core-0.name}"
}
resource "google_compute_subnetwork" "prod-cf-core-1" {
  name          = "${var.google_network_name}-prod-cf-core-1"
  ip_cidr_range = "${var.network}.53.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-core-1.name" {
  value = "${google_compute_subnetwork.prod-cf-core-1.name}"
}
resource "google_compute_subnetwork" "prod-cf-core-2" {
  name          = "${var.google_network_name}-prod-cf-core-2"
  ip_cidr_range = "${var.network}.54.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-core-2.name" {
  value = "${google_compute_subnetwork.prod-cf-core-2.name}"
}

###############################################################
# PROD-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "prod-cf-runtime-0" {
  name          = "${var.google_network_name}-prod-cf-runtime-0"
  ip_cidr_range = "${var.network}.55.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-runtime-0.name" {
  value = "${google_compute_subnetwork.prod-cf-runtime-0.name}"
}
resource "google_compute_subnetwork" "prod-cf-runtime-1" {
  name          = "${var.google_network_name}-prod-cf-runtime-1"
  ip_cidr_range = "${var.network}.56.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-runtime-1.name" {
  value = "${google_compute_subnetwork.prod-cf-runtime-1.name}"
}
resource "google_compute_subnetwork" "prod-cf-runtime-2" {
  name          = "${var.google_network_name}-prod-cf-runtime-2"
  ip_cidr_range = "${var.network}.57.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-runtime-2.name" {
  value = "${google_compute_subnetwork.prod-cf-runtime-2.name}"
}

###############################################################
# PROD-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "prod-cf-svc-0" {
  name          = "${var.google_network_name}-prod-cf-svc-0"
  ip_cidr_range = "${var.network}.58.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-svc-0.name" {
  value = "${google_compute_subnetwork.prod-cf-svc-0.name}"
}
resource "google_compute_subnetwork" "prod-cf-svc-1" {
  name          = "${var.google_network_name}-prod-cf-svc-1"
  ip_cidr_range = "${var.network}.59.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-svc-1.name" {
  value = "${google_compute_subnetwork.prod-cf-svc-1.name}"
}
resource "google_compute_subnetwork" "prod-cf-svc-2" {
  name          = "${var.google_network_name}-prod-cf-svc-2"
  ip_cidr_range = "${var.network}.60.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-svc-2.name" {
  value = "${google_compute_subnetwork.prod-cf-svc-2.name}"
}



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######

###############################################################
# DMZ - De-militarized Zone
#
resource "google_compute_firewall" "dmz" {
  name    = "${var.google_network_name}-dmz"
  network = "${google_compute_network.default.name}"

  # Allow ICMP traffic
  allow {
    protocol = "icmp"
  }

  # Allow SSH traffic into the Bastion box
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.google_network_name}-dmz"]
}
output "google.firewall.dmz.name" {
  value = "${google_compute_firewall.dmz.name}"
}

###############################################################
# GLOBAL - Global Site
#
resource "google_compute_firewall" "global-internal" {
  name    = "${var.google_network_name}-global-internal"
  network = "${google_compute_network.default.name}"

  # Allow ICMP traffic
  allow {
    protocol = "icmp"
  }

  # Allow TCP traffic
  allow {
    protocol = "tcp"
  }

  # Allow UDP traffic
  allow {
    protocol = "udp"
  }

  source_tags = ["${var.google_network_name}-global-internal"]
  target_tags = ["${var.google_network_name}-global-internal"]
}
output "google.firewall.global-internal.name" {
  value = "${google_compute_firewall.global-internal.name}"
}

resource "google_compute_firewall" "global-external" {
  name    = "${var.google_network_name}-global-external"
  network = "${google_compute_network.default.name}"

  # Allow HTTP traffic
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Allow HTTPS traffic
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["${var.google_network_name}-global-external"]
}
output "google.firewall.global-external.name" {
  value = "${google_compute_firewall.global-external.name}"
}

###############################################################
# DEV - Development Site
#
resource "google_compute_firewall" "dev-internal" {
  name    = "${var.google_network_name}-dev-internal"
  network = "${google_compute_network.default.name}"

  # Allow ICMP traffic
  allow {
    protocol = "icmp"
  }

  # Allow TCP traffic
  allow {
    protocol = "tcp"
  }

  # Allow UDP traffic
  allow {
    protocol = "udp"
  }

  source_tags = ["${var.google_network_name}-dev-internal"]
  target_tags = ["${var.google_network_name}-dev-internal"]
}
output "google.firewall.dev-internal.name" {
  value = "${google_compute_firewall.dev-internal.name}"
}

resource "google_compute_firewall" "dev-external" {
  name    = "${var.google_network_name}-dev-external"
  network = "${google_compute_network.default.name}"

  # Allow HTTP traffic
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Allow HTTPS traffic
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Allow Diego SSH traffic
  allow {
    protocol = "tcp"
    ports    = ["2222"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["${var.google_network_name}-dev-external"]
}
output "google.firewall.dev-external.name" {
  value = "${google_compute_firewall.dev-external.name}"
}

###############################################################
# STAGING - Staging Site
#
resource "google_compute_firewall" "staging-internal" {
  name    = "${var.google_network_name}-staging-internal"
  network = "${google_compute_network.default.name}"

  # Allow ICMP traffic
  allow {
    protocol = "icmp"
  }

  # Allow TCP traffic
  allow {
    protocol = "tcp"
  }

  # Allow UDP traffic
  allow {
    protocol = "udp"
  }

  source_tags = ["${var.google_network_name}-staging-internal"]
  target_tags = ["${var.google_network_name}-staging-internal"]
}
output "google.firewall.staging-internal.name" {
  value = "${google_compute_firewall.staging-internal.name}"
}

resource "google_compute_firewall" "staging-external" {
  name    = "${var.google_network_name}-staging-external"
  network = "${google_compute_network.default.name}"

  # Allow HTTP traffic
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Allow HTTPS traffic
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Allow Diego SSH traffic
  allow {
    protocol = "tcp"
    ports    = ["2222"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["${var.google_network_name}-staging-external"]
}
output "google.firewall.staging-external.name" {
  value = "${google_compute_firewall.staging-external.name}"
}

###############################################################
# PROD - Production Site
#
resource "google_compute_firewall" "prod-internal" {
  name    = "${var.google_network_name}-prod-internal"
  network = "${google_compute_network.default.name}"

  # Allow ICMP traffic
  allow {
    protocol = "icmp"
  }

  # Allow TCP traffic
  allow {
    protocol = "tcp"
  }

  # Allow UDP traffic
  allow {
    protocol = "udp"
  }

  source_tags = ["${var.google_network_name}-prod-internal"]
  target_tags = ["${var.google_network_name}-prod-internal"]
}
output "google.firewall.prod-internal.name" {
  value = "${google_compute_firewall.prod-internal.name}"
}

resource "google_compute_firewall" "prod-external" {
  name    = "${var.google_network_name}-prod-external"
  network = "${google_compute_network.default.name}"

  # Allow HTTP traffic
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Allow HTTP traffic
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Allow Diego SSH traffic
  allow {
    protocol = "tcp"
    ports    = ["2222"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["${var.google_network_name}-prod-external"]
}
output "google.firewall.prod-external.name" {
  value = "${google_compute_firewall.prod-external.name}"
}



##       ########   ######
##       ##     ## ##    ##
##       ##     ## ##
##       ########   ######
##       ##     ##       ##
##       ##     ## ##    ##
######## ########   ######

###############################################################
# DEV-CF-LB - Cloud Foundry Load Balancers
#
resource "google_compute_address" "dev-cf" {
  count  = "${var.google_lb_dev_enabled}"
  name   = "${var.google_network_name}-dev-cf"
  region = "${var.google_region}"
}
output "google.target-pool.dev-cf.address" {
  value = "${google_compute_address.dev-cf.address}"
}
resource "google_compute_http_health_check" "dev-cf" {
  count = "${var.google_lb_dev_enabled}"
  name  = "${var.google_network_name}-dev-cf"

  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 10
  unhealthy_threshold = 2
  port                = 80
  request_path        = "/info"
  host                = "api.system.${google_compute_address.dev-cf.address}.xip.io"
}
resource "google_compute_target_pool" "dev-cf" {
  count  = "${var.google_lb_dev_enabled}"
  name   = "${var.google_network_name}-dev-cf"
  region = "${var.google_region}"

  health_checks = [
    "${google_compute_http_health_check.dev-cf.name}",
  ]
}
resource "google_compute_forwarding_rule" "dev-cf-http" {
  count       = "${var.google_lb_dev_enabled}"
  name        = "${var.google_network_name}-dev-cf-http"
  ip_address  = "${google_compute_address.dev-cf.address}"
  ip_protocol = "TCP"
  port_range  = "80-80"
  target      = "${google_compute_target_pool.dev-cf.self_link}"
}
resource "google_compute_forwarding_rule" "dev-cf-https" {
  count       = "${var.google_lb_dev_enabled}"
  name        = "${var.google_network_name}-dev-cf-https"
  ip_address  = "${google_compute_address.dev-cf.address}"
  ip_protocol = "TCP"
  port_range  = "443-443"
  target      = "${google_compute_target_pool.dev-cf.self_link}"
}
resource "google_compute_target_pool" "dev-cf-ssh" {
  count = "${var.google_lb_dev_enabled}"
  name  = "${var.google_network_name}-dev-cf-ssh"
}
resource "google_compute_forwarding_rule" "dev-cf-ssh" {
  count       = "${var.google_lb_dev_enabled}"
  name        = "${var.google_network_name}-dev-cf-ssh"
  ip_address  = "${google_compute_address.dev-cf.address}"
  ip_protocol = "TCP"
  port_range  = "2222-2222"
  target      = "${google_compute_target_pool.dev-cf-ssh.self_link}"
}
output "google.target-pool.dev-cf.name" {
  value = "${google_compute_target_pool.dev-cf.name}"
}
output "google.target-pool.dev-cf-ssh.name" {
  value = "${google_compute_target_pool.dev-cf-ssh.name}"
}

###############################################################
# STAGING-CF-LB - Cloud Foundry Load Balancers
#
resource "google_compute_address" "staging-cf" {
  count  = "${var.google_lb_staging_enabled}"
  name   = "${var.google_network_name}-staging-cf"
  region = "${var.google_region}"
}
output "google.target-pool.staging-cf.address" {
  value = "${google_compute_address.staging-cf.address}"
}
resource "google_compute_http_health_check" "staging-cf" {
  count = "${var.google_lb_staging_enabled}"
  name  = "${var.google_network_name}-staging-cf"

  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 10
  unhealthy_threshold = 2
  port                = 80
  request_path        = "/info"
  host                = "api.system.${google_compute_address.staging-cf.address}.xip.io"
}
resource "google_compute_target_pool" "staging-cf" {
  count  = "${var.google_lb_staging_enabled}"
  name   = "${var.google_network_name}-staging-cf"
  region = "${var.google_region}"

  health_checks = [
    "${google_compute_http_health_check.staging-cf.name}",
  ]
}
resource "google_compute_forwarding_rule" "staging-cf-http" {
  count       = "${var.google_lb_staging_enabled}"
  name        = "${var.google_network_name}-staging-cf-http"
  ip_address  = "${google_compute_address.staging-cf.address}"
  ip_protocol = "TCP"
  port_range  = "80-80"
  target      = "${google_compute_target_pool.staging-cf.self_link}"
}
resource "google_compute_forwarding_rule" "staging-cf-https" {
  count       = "${var.google_lb_staging_enabled}"
  name        = "${var.google_network_name}-staging-cf-https"
  ip_address  = "${google_compute_address.staging-cf.address}"
  ip_protocol = "TCP"
  port_range  = "443-443"
  target      = "${google_compute_target_pool.staging-cf.self_link}"
}
resource "google_compute_target_pool" "staging-cf-ssh" {
  count = "${var.google_lb_staging_enabled}"
  name  = "${var.google_network_name}-staging-cf-ssh"
}
resource "google_compute_forwarding_rule" "staging-cf-ssh" {
  count       = "${var.google_lb_staging_enabled}"
  name        = "${var.google_network_name}-staging-cf-ssh"
  ip_address  = "${google_compute_address.staging-cf.address}"
  ip_protocol = "TCP"
  port_range  = "2222-2222"
  target      = "${google_compute_target_pool.staging-cf-ssh.self_link}"
}
output "google.target-pool.staging-cf.name" {
  value = "${google_compute_target_pool.staging-cf.name}"
}
output "google.target-pool.staging-cf-ssh.name" {
  value = "${google_compute_target_pool.staging-cf-ssh.name}"
}

###############################################################
# PROD-CF-LB - Cloud Foundry Load Balancers
#
resource "google_compute_address" "prod-cf" {
  count  = "${var.google_lb_prod_enabled}"
  name   = "${var.google_network_name}-prod-cf"
  region = "${var.google_region}"
}
output "google.target-pool.prod-cf.address" {
  value = "${google_compute_address.prod-cf.address}"
}
resource "google_compute_http_health_check" "prod-cf" {
  count = "${var.google_lb_prod_enabled}"
  name  = "${var.google_network_name}-prod-cf"

  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 10
  unhealthy_threshold = 2
  port                = 80
  request_path        = "/info"
  host                = "api.system.${google_compute_address.prod-cf.address}.xip.io"
}
resource "google_compute_target_pool" "prod-cf" {
  count  = "${var.google_lb_prod_enabled}"
  name   = "${var.google_network_name}-prod-cf"
  region = "${var.google_region}"

  health_checks = [
    "${google_compute_http_health_check.prod-cf.name}",
  ]
}
resource "google_compute_forwarding_rule" "prod-cf-http" {
  count       = "${var.google_lb_prod_enabled}"
  name        = "${var.google_network_name}-prod-cf-http"
  ip_address  = "${google_compute_address.prod-cf.address}"
  ip_protocol = "TCP"
  port_range  = "80-80"
  target      = "${google_compute_target_pool.prod-cf.self_link}"
}
resource "google_compute_forwarding_rule" "prod-cf-https" {
  count       = "${var.google_lb_prod_enabled}"
  name        = "${var.google_network_name}-prod-cf-https"
  ip_address  = "${google_compute_address.prod-cf.address}"
  ip_protocol = "TCP"
  port_range  = "443-443"
  target      = "${google_compute_target_pool.prod-cf.self_link}"
}
resource "google_compute_target_pool" "prod-cf-ssh" {
  count = "${var.google_lb_prod_enabled}"
  name  = "${var.google_network_name}-prod-cf-ssh"
}
resource "google_compute_forwarding_rule" "prod-cf-ssh" {
  count       = "${var.google_lb_prod_enabled}"
  name        = "${var.google_network_name}-prod-cf-ssh"
  ip_address  = "${google_compute_address.prod-cf.address}"
  ip_protocol = "TCP"
  port_range  = "2222-2222"
  target      = "${google_compute_target_pool.prod-cf-ssh.self_link}"
}
output "google.target-pool.prod-cf.name" {
  value = "${google_compute_target_pool.prod-cf.name}"
}
output "google.target-pool.prod-cf-ssh.name" {
  value = "${google_compute_target_pool.prod-cf-ssh.name}"
}



########     ###     ######  ######## ####  #######  ##    ##
##     ##   ## ##   ##    ##    ##     ##  ##     ## ###   ##
##     ##  ##   ##  ##          ##     ##  ##     ## ####  ##
########  ##     ##  ######     ##     ##  ##     ## ## ## ##
##     ## #########       ##    ##     ##  ##     ## ##  ####
##     ## ##     ## ##    ##    ##     ##  ##     ## ##   ###
########  ##     ##  ######     ##    ####  #######  ##    ##

resource "google_compute_address" "bastion" {
  name   = "bastion"
  region = "${var.google_region}"
}

resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "${var.bastion_machine_type}"
  zone         = "${var.google_region}-${var.google_zone_1}"
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.dmz.name}"
    access_config {
      nat_ip = "${google_compute_address.bastion.address}"
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["${google_compute_firewall.dmz.name}", "${var.google_network_name}-global-internal"]

  metadata_startup_script = <<EOT
#!/bin/bash
sudo curl -o /usr/local/bin/jumpbox https://raw.githubusercontent.com/starkandwayne/jumpbox/master/bin/jumpbox
sudo chmod 0755 /usr/local/bin/jumpbox
sudo jumpbox system
EOT
}
output "box.bastion.name" {
  value = "${google_compute_instance.bastion.name}"
}
output "box.bastion.region" {
  value = "${var.google_region}"
}
output "box.bastion.zone" {
  value = "${google_compute_instance.bastion.zone}"
}
output "box.bastion.public_ip" {
  value = "${google_compute_address.bastion.address}"
}
