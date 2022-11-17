# Network

All network devices are from Ubiquiti and are part of their Unifi brand.

## Router (UDM-PRO)

### NextDNS

We have four configurations on NextDNS:

* mobile (for when we are outside of the network)
* non blocking (used by devices on the network that should not have Ad blocking enabled)
* blocking (used by devices on the network that should have Ad blocking enabled)
* safe browsing (used on devices that kids uses)

#### VLAN config

The NextDNS cli will pick up all requests sent to `192.168.*.1` and redirect them to NextDNS.

#### k8s-gateway

We have k8s-gateway running in the cluster. We have configured NextDNS to use split horizon to forward everything regarding our internal domain to k8s-domain.
This fixes issues with accessing internal services when the internet connection is down.

#### Install NextDNS cli

SSH to the router and run `sh -c 'sh -c "$(curl -sL https://nextdns.io/install)"'`

#### Configure NextDNS cli

```shell
nextdns config set \
    -config 192.168.30.0/24=<config1> \
    -config 192.168.50.0/24=<config4> \
    -config 192.168.60.0/24=<config1> \
    -config 192.168.70.0/24=<config1> \
    -config 192.168.71.0/24=<config1> \
    -config <config2> \
    -forwarder <domain>=192.168.20.208
nextdns restart
```
