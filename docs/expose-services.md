# 🔐 DNS & Ingresses
We use Nginx as our ingress to serve the different services in the cluster. Some services are only accessible from the local LAN. This is done by using **External DNS** that updates Cloudflare with DNS records, but only if an ingress is annotated with `external-dns/is-public: "true"`. Ingresses without this annotation will only be accessible from the local LAN.

Cloudflare-DDNS is used to keep all the records up to date when the public IP changes. We do also use Cloudflare for proxying all the traffic coming in to the cluster from the internet. [Cloudflare](https://cloudflare.com) also has a firewall that we use and one of the rules blocks most of the countries in the world. On my own firewall I have blocked all traffic on port `443` that does not originate from [Cloudflares list of IP ranges](https://www.cloudflare.com/ips/)

Cert-Manager keeps a wildcard SSL certificate up to date.

Internally on the local LAN we have DNS servers with a wildcard dns-record pointing to the Kubernetes loadbalancer that's assigned to Nginx.

This means that Cloudflare is only updated with records for those services that should be accessible from the internet while our local DNS servers has a wildcard record making all services accessible from the local LAN.
