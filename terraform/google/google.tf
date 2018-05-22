#
# Amazonia - Terraform Configuration for
# GCP BOSH + Cloud Foundry
#

variable "google_project"      {} # Your Google Project Id  (required)
variable "google_network_name" {} # Name of the Network     (required)
variable "google_credentials"  {} # Credential file path    (required)
variable "google_region"       {} # Google Region           (required)
variable "google_pubkey_file"  {} # Google SSH Public Key   (required)
variable "google_az1"          {} # Google Zone 1           (required)
# we don't need az2 or az3; GCP doesn't  require a subnet per zone

variable "network"              { default = "10.4" }          # First 2 octets of your /16
variable "bastion_machine_type" { default = "n1-standard-1" } # Bastion Machine Type

variable "google_lb_dev_enabled"     { default = 1 } # Set to 1 to create the DEV LB
variable "google_lb_staging_enabled" { default = 1 } # Set to 1 to create the STAGING LB
variable "google_lb_prod_enabled"    { default = 1 } # Set to 1 to create the PROD LB

variable "latest_ubuntu" { default = "ubuntu-os-cloud/ubuntu-1804-lts" }

###############################################################

provider "google" {
  credentials = "${file("${var.google_credentials}")}"
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

resource "google_compute_address" "nat" {
  name   = "nat"
  region = "${var.google_region}"
}
resource "google_compute_instance" "nat" {
  name         = "nat"
  machine_type = "n1-standard-1"
  zone         = "${var.google_region}-${var.google_az1}"

  boot_disk {
    initialize_params {
      image = "${var.latest_ubuntu}"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.global-infra.name}"
    subnetwork_project = "${var.google_project}"
    access_config {
      nat_ip = "${google_compute_address.nat.address}"
    }
  }

  can_ip_forward = true

  tags = ["ssh"]

  metadata {
    sshKeys = "ubuntu:${file(var.google_pubkey_file)}"
  }

  metadata_startup_script = <<EOT
#!/bin/bash
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOT
}
output "box.nat.name" {
  value = "${google_compute_instance.nat.name}"
}
output "box.nat.region" {
  value = "${var.google_region}"
}
output "box.nat.zone" {
  value = "${google_compute_instance.nat.zone}"
}
output "box.nat.public_ip" {
  value = "${google_compute_address.nat.address}"
}

resource "google_compute_route" "nat" {
  name                   = "${var.google_network_name}-nat"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.default.self_link}"
  next_hop_instance      = "${google_compute_instance.nat.name}"
  next_hop_instance_zone = "${var.google_region}-${var.google_az1}"
  priority               = 800
  tags                   = ["nattable"]
  project                = "${var.google_project}"
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
resource "google_compute_subnetwork" "global-infra" {
  name          = "${var.google_network_name}-global-infra"
  network       = "${google_compute_network.default.self_link}"
  ip_cidr_range = "${var.network}.1.0/24"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-infra.name" {
  value = "${google_compute_subnetwork.global-infra.name}"
}

###############################################################
# OpenVPN - OpenVPN
#
resource "google_compute_subnetwork" "global-openvpn" {
  name          = "${var.google_network_name}-global-openvpn"
  ip_cidr_range = "${var.network}.2.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.global-openvpn.name" {
  value = "${google_compute_subnetwork.global-openvpn.name}"
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
resource "google_compute_subnetwork" "dev-infra" {
  name          = "${var.google_network_name}-dev-infra"
  ip_cidr_range = "${var.network}.16.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-infra.name" {
  value = "${google_compute_subnetwork.dev-infra.name}"
}

###############################################################
# DEV-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "dev-cf-edge" {
  name          = "${var.google_network_name}-dev-cf-edge"
  ip_cidr_range = "${var.network}.17.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-edge.name" {
  value = "${google_compute_subnetwork.dev-cf-edge.name}"
}

###############################################################
# DEV-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "dev-cf-core" {
  name          = "${var.google_network_name}-dev-cf-core"
  ip_cidr_range = "${var.network}.18.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-core.name" {
  value = "${google_compute_subnetwork.dev-cf-core.name}"
}

###############################################################
# DEV-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "dev-cf-runtime" {
  name          = "${var.google_network_name}-dev-cf-runtime"
  ip_cidr_range = "${var.network}.19.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-runtime.name" {
  value = "${google_compute_subnetwork.dev-cf-runtime.name}"
}

###############################################################
# DEV-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "dev-cf-svc" {
  name          = "${var.google_network_name}-dev-cf-svc"
  ip_cidr_range = "${var.network}.20.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.dev-cf-svc.name" {
  value = "${google_compute_subnetwork.dev-cf-svc.name}"
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
resource "google_compute_subnetwork" "staging-infra" {
  name          = "${var.google_network_name}-staging-infra"
  ip_cidr_range = "${var.network}.32.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-infra.name" {
  value = "${google_compute_subnetwork.staging-infra.name}"
}

###############################################################
# STAGING-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "staging-cf-edge" {
  name          = "${var.google_network_name}-staging-cf-edge"
  ip_cidr_range = "${var.network}.33.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-edge.name" {
  value = "${google_compute_subnetwork.staging-cf-edge.name}"
}

###############################################################
# STAGING-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "staging-cf-core" {
  name          = "${var.google_network_name}-staging-cf-core"
  ip_cidr_range = "${var.network}.34.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-core.name" {
  value = "${google_compute_subnetwork.staging-cf-core.name}"
}

###############################################################
# STAGING-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "staging-cf-runtime" {
  name          = "${var.google_network_name}-staging-cf-runtime"
  ip_cidr_range = "${var.network}.35.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-runtime.name" {
  value = "${google_compute_subnetwork.staging-cf-runtime.name}"
}

###############################################################
# STAGING-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "staging-cf-svc" {
  name          = "${var.google_network_name}-staging-cf-svc"
  ip_cidr_range = "${var.network}.36.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.staging-cf-svc.name" {
  value = "${google_compute_subnetwork.staging-cf-svc.name}"
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
resource "google_compute_subnetwork" "prod-infra" {
  name          = "${var.google_network_name}-prod-infra"
  ip_cidr_range = "${var.network}.48.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-infra.name" {
  value = "${google_compute_subnetwork.prod-infra.name}"
}

###############################################################
# PROD-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#
resource "google_compute_subnetwork" "prod-cf-edge" {
  name          = "${var.google_network_name}-prod-cf-edge"
  ip_cidr_range = "${var.network}.49.0/25"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-edge.name" {
  value = "${google_compute_subnetwork.prod-cf-edge.name}"
}

###############################################################
# PROD-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#
resource "google_compute_subnetwork" "prod-cf-core" {
  name          = "${var.google_network_name}-prod-cf-core"
  ip_cidr_range = "${var.network}.50.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-core.name" {
  value = "${google_compute_subnetwork.prod-cf-core.name}"
}

###############################################################
# PROD-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#
resource "google_compute_subnetwork" "prod-cf-runtime" {
  name          = "${var.google_network_name}-prod-cf-runtime"
  ip_cidr_range = "${var.network}.51.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-runtime.name" {
  value = "${google_compute_subnetwork.prod-cf-runtime.name}"
}

###############################################################
# PROD-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#
resource "google_compute_subnetwork" "prod-cf-svc" {
  name          = "${var.google_network_name}-prod-cf-svc"
  ip_cidr_range = "${var.network}.52.0/24"
  network       = "${google_compute_network.default.self_link}"
  region        = "${var.google_region}"
}
output "google.subnetwork.prod-cf-svc.name" {
  value = "${google_compute_subnetwork.prod-cf-svc.name}"
}



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######

###############################################################
# SSH - Ingress SSH from the outside world (or wherever)
#
###############################################################
# OUTBOUND - Allow all egress traffic
#
resource "google_compute_firewall" "outbound" {
  name      = "outbound"
  network   = "${google_compute_network.default.name}"
  direction = "EGRESS"

  # Allow all TCP/UDP/SCTP/ICMP traffic
  allow { protocol = "all" }

  # no target_tags; apply to everyone!
}

###############################################################
# SSH - Inbound SSH (for the NAT)
#
resource "google_compute_firewall" "ssh" {
  name      = "ssh"
  network   = "${google_compute_network.default.name}"
  direction = "INGRESS"

  # Allow all TCP/UDP/SCTP/ICMP traffic
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

###############################################################
# DMZ - De-militarized Zone
#
resource "google_compute_firewall" "dmz" {
  name      = "dmz"
  network   = "${google_compute_network.default.name}"
  direction = "INGRESS"

  # Allow all TCP/UDP/SCTP/ICMP traffic
  allow { protocol = "all" }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz"]
}

###############################################################
# INTERNAL - Allow us to talk to ourselves (for therapy)
#

resource "google_compute_firewall" "internal" {
  name      = "internal"
  network   = "${google_compute_network.default.name}"
  direction = "INGRESS"

  # Allow all traffic from us, to us
  allow { protocol = "all" }

  source_ranges = ["${var.network}.0.0/16"]
  # no target_tags; apply to everyone!
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
  host                = "api.system.${google_compute_address.dev-cf.address}.netip.cc"
}
resource "google_compute_target_pool" "dev-cf" {
  count  = "${var.google_lb_dev_enabled}"
  name   = "${var.google_network_name}-dev-cf"
  region = "${var.google_region}"

  health_checks = [ "${google_compute_http_health_check.dev-cf.name}" ]
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
  host                = "api.system.${google_compute_address.staging-cf.address}.netip.cc"
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
  host                = "api.system.${google_compute_address.prod-cf.address}.netip.cc"
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
  zone         = "${var.google_region}-${var.google_az1}"

  boot_disk {
    initialize_params {
      image = "${var.latest_ubuntu}"
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

  tags = ["dmz"]

  metadata {
    sshKeys = "ubuntu:${file(var.google_pubkey_file)}"
  }

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
