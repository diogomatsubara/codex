# Network Design

When designing networks for BOSH and Cloud Foundry there are some terms and
concepts to be familiar with, including the following:

* [Network Address Translation]
* [Bastion Host]
* [RFC 1918]

And a great tool to have installed is `sipcalc` for doing math on CIDR notaion
ranges.  A good example is shown below when displaying how many hosts are available
in the `10.4.0.0/16` network.

This guide will give an overview of why we've defined our example network this way.

Wile our [terraform scripts] will give you example code to build, where you can
bring your own credentials and build on the cloud of your choice.

## Supernet

Let's use `sipcalc` to calcuate how many hosts are available in the `10.4.0.0/16`
Supernet.

	$ sipcalc 10.4.0.0/16

	[CIDR]
	Host address            - 10.4.0.0
	Host address (decimal)  - 168034304
	Host address (hex)      - A040000
	Network address         - 10.4.0.0
	Network mask            - 255.255.0.0
	Network mask (bits)     - 16
	Network mask (hex)      - FFFF0000
	Broadcast address       - 10.4.255.255
	Cisco wildcard          - 0.0.255.255
	Addresses in network    - 65536
	Network range           - 10.4.0.0 - 10.4.255.255
	Usable range            - 10.4.0.1 - 10.4.255.254

That provides over **65k** hosts!  If we were to split into `/24` subnets
(a common size) we'd have **255** subnets with 254 hosts in each subnet.  This is
plenty to work with.

We're going to design a network that has four parts.  A **global management network**,
then three incremental release sites of **Dev**, **Staging** and **Production**.

## Network Subdivision

In the table below you'll see things grouped together, first by the site's `/20`
then into subnets we'll use to manage deployments in those sites.  For example:

Global `10.4.0.0/20` and the `dmz` deployment subnet using `10.4.0.0/24` subnet.

| (Site) Subnet          | Hosts | Zone  | Name                 | Purpose                 |
|------------------------|-------|-------|----------------------|-------------------------|
| (Global) 10.4.0.0/20   | 4096  |       |                      |                         |
| 10.4.0.0/24            |  254  |     1 | dmz                  | NAT / bastion / etc.    |
| 10.4.1.0/24            |  254  |     1 | global-infra-0       | Global Infrastructure   |
| 10.4.2.0/24            |  254  |     2 | global-infra-1       | Global Infrastructure   |
| 10.4.3.0/24            |  254  |     3 | global-infra-2       | Global Infrastructure   |
| 10.4.4.0/25            |  126  |     1 | global-openvpn-0     | Global OpenVPN          |
| 10.4.4.128/25          |  126  |     2 | global-openvpn-1     | Global OpenVPN          |
| (Dev) 10.4.16.0/20     | 4096  |       |                      |                         |
| 10.4.16.0/24           |  254  |     1 | dev-infra-0          | Site Infrastructure     |
| 10.4.17.0/24           |  254  |     2 | dev-infra-1          | Site Infrastructure     |
| 10.4.18.0/24           |  254  |     3 | dev-infra-2          | Site Infrastructure     |
| 10.4.19.0/25           |  126  |     1 | dev-cf-edge-0        | Cloud Foundry Routers   |
| 10.4.19.128/25         |  126  |     2 | dev-cf-edge-1        | Cloud Foundry Routers   |
| 10.4.20.0/24           |  254  |     1 | dev-cf-core-0        | Cloud Foundry Core      |
| 10.4.21.0/24           |  254  |     2 | dev-cf-core-1        | Cloud Foundry Core      |
| 10.4.22.0/24           |  254  |     3 | dev-cf-core-2        | Cloud Foundry Core      |
| 10.4.23.0/24           |  254  |     1 | dev-cf-runtime-0     | Cloud Foundry Runtime   |
| 10.4.24.0/24           |  254  |     2 | dev-cf-runtime-1     | Cloud Foundry Runtime   |
| 10.4.25.0/24           |  254  |     3 | dev-cf-runtime-2     | Cloud Foundry Runtime   |
| 10.4.26.0/24           |  254  |     1 | dev-cf-svc-0         | Cloud Foundry Services  |
| 10.4.27.0/24           |  254  |     2 | dev-cf-svc-1         | Cloud Foundry Services  |
| 10.4.28.0/24           |  254  |     3 | dev-cf-svc-2         | Cloud Foundry Services  |
| 10.4.29.0/28           |   14  |     1 | dev-cf-db-0          | Cloud Foundry Databases |
| 10.4.29.16/28          |   14  |     2 | dev-cf-db-1          | Cloud Foundry Databases |
| 10.4.29.32/28          |   14  |     3 | dev-cf-db-2          | Cloud Foundry Databases |
| (Staging) 10.4.32.0/20 | 4096  |       |                      |                         |
| 10.4.32.0/24           |  254  |     1 | staging-infra-0      | Site Infrastructure     |
| 10.4.33.0/24           |  254  |     2 | staging-infra-1      | Site Infrastructure     |
| 10.4.34.0/24           |  254  |     3 | staging-infra-2      | Site Infrastructure     |
| 10.4.35.0/25           |  126  |     1 | staging-cf-edge-0    | Cloud Foundry Routers   |
| 10.4.35.128/25         |  126  |     2 | staging-cf-edge-1    | Cloud Foundry Routers   |
| 10.4.36.0/24           |  254  |     1 | staging-cf-core-0    | Cloud Foundry Core      |
| 10.4.37.0/24           |  254  |     2 | staging-cf-core-1    | Cloud Foundry Core      |
| 10.4.38.0/24           |  254  |     3 | staging-cf-core-2    | Cloud Foundry Core      |
| 10.4.39.0/24           |  254  |     1 | staging-cf-runtime-0 | Cloud Foundry Runtime   |
| 10.4.40.0/24           |  254  |     2 | staging-cf-runtime-1 | Cloud Foundry Runtime   |
| 10.4.41.0/24           |  254  |     3 | staging-cf-runtime-2 | Cloud Foundry Runtime   |
| 10.4.42.0/24           |  254  |     1 | staging-cf-svc-0     | Cloud Foundry Services  |
| 10.4.43.0/24           |  254  |     2 | staging-cf-svc-1     | Cloud Foundry Services  |
| 10.4.44.0/24           |  254  |     3 | staging-cf-svc-2     | Cloud Foundry Services  |
| 10.4.45.0/28           |   14  |     1 | staging-cf-db-0      | Cloud Foundry Databases |
| 10.4.45.16/28          |   14  |     2 | staging-cf-db-1      | Cloud Foundry Databases |
| 10.4.45.32/28          |   14  |     3 | staging-cf-db-2      | Cloud Foundry Databases |
| (Prod) 10.4.48.0/20    | 4096  |       |                      |                         |
| 10.4.48.0/24           |  254  |     1 | prod-infra-0         | Site Infrastructure     |
| 10.4.49.0/24           |  254  |     2 | prod-infra-1         | Site Infrastructure     |
| 10.4.50.0/24           |  254  |     3 | prod-infra-2         | Site Infrastructure     |
| 10.4.51.0/25           |  126  |     1 | prod-cf-edge-0       | Cloud Foundry Routers   |
| 10.4.51.128/25         |  126  |     2 | prod-cf-edge-1       | Cloud Foundry Routers   |
| 10.4.52.0/24           |  254  |     1 | prod-cf-core-0       | Cloud Foundry Core      |
| 10.4.53.0/24           |  254  |     2 | prod-cf-core-1       | Cloud Foundry Core      |
| 10.4.54.0/24           |  254  |     3 | prod-cf-core-2       | Cloud Foundry Core      |
| 10.4.55.0/24           |  254  |     1 | prod-cf-runtime-0    | Cloud Foundry Runtime   |
| 10.4.56.0/24           |  254  |     2 | prod-cf-runtime-1    | Cloud Foundry Runtime   |
| 10.4.57.0/24           |  254  |     3 | prod-cf-runtime-2    | Cloud Foundry Runtime   |
| 10.4.58.0/24           |  254  |     1 | prod-cf-svc-0        | Cloud Foundry Services  |
| 10.4.59.0/24           |  254  |     2 | prod-cf-svc-1        | Cloud Foundry Services  |
| 10.4.60.0/24           |  254  |     3 | prod-cf-svc-2        | Cloud Foundry Services  |
| 10.4.61.0/28           |   14  |     1 | prod-cf-db-0         | Cloud Foundry Databases |
| 10.4.61.16/28          |   14  |     2 | prod-cf-db-1         | Cloud Foundry Databases |
| 10.4.61.32/28          |   14  |     3 | prod-cf-db-2         | Cloud Foundry Databases |

Global Infrastructure IP Allocation
-----------------------------------

The `global` "site" consists of three zone-isolated subnets.  Inside of those
subnets, we can further sub-divide (albeit purely for allocation's sake) for
the different infrastructural deployments.  Note that these sub-divisions
will not introduce new gateways, netmasks or broadcast addresses, rather
they merely serve to slice up the `/24` networks for fairly small
deployments.


| Deployment | "Subnet"     | #   | Zone | Purpose                         |
|------------|--------------|-----|------|---------------------------------|
| bosh       | 10.4.1.0/28  |  16 |    1 | proto-BOSH director             |
| vault      | 10.4.1.16/28 |  16 |    1 | Secure Vault                    |
| vault      | 10.4.2.16/28 |  16 |    2 | Secure Vault                    |
| vault      | 10.4.3.16/28 |  16 |    3 | Secure Vault                    |
| shield     | 10.4.1.32/28 |  16 |    1 | SHIELD Backup/Restore Core      |
| concourse  | 10.4.1.48/28 |  16 |    1 | Runway Concourse                |
| concourse  | 10.4.2.48/28 |  16 |    2 | Concourse overflow              |
| Prometheus | 10.4.1.64/28 |  16 |    1 | Monitoring                      |
| alpha site | 10.4.1.80/28 |  16 |    1 | alpha site bosh-lite            |


Most infrastructural deployments are not highly available, nor even
HA-capable, so they do not need to be striped across the three zone-isolated
subnets.  Vault is the only HA deployment in the bunch, however, so it
*is* deployed across three `/28` ranges, one per subnet.

## Build a Network

Once again, you can test out this network design by reading through, cloning our
[terraform scripts], and providing your credentials.  Read more Terraform
specific help in each guide we have here.

[Bastion Host]: https://en.wikipedia.org/wiki/Bastion_host
[RFC 1918]: https://tools.ietf.org/html/rfc1918
[Network Address Translation]: https://en.wikipedia.org/wiki/Network_address_translation
[terraform scripts]: https://github.com/starkandwayne/codex/tree/master/terraform
