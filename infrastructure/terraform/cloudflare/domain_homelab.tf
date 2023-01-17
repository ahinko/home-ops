module "cf_domain_homelab" {
  source     = "./modules/cf_domain"
  domain     = data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"]
  account_id = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  dns_entries = [
    {
      id    = "ipv4"
      name  = "ipv4"
      value = local.home_ipv4
    },
    {
      id      = "www"
      name    = "www"
      value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"]}"
      type    = "CNAME"
      ttl     = 1
      proxied = true
    },
    {
      id      = "frovalla_tunnel"
      name    = "frovalla"
      value   = "c60eab22-c34b-457a-823d-28cb2076b37c.cfargotunnel.com"
      type    = "CNAME"
      ttl     = 1
      proxied = true
    },
    {
      id    = "mx_no_mail"
      name  = "@"
      value = "."
      type  = "MX"
      ttl   = 1
    },
    {
      id    = "dmarc_no_mail"
      name  = "_dmarc"
      value = "v=DMARC1;p=reject;sp=reject;adkim=s;aspf=s"
      type  = "TXT"
      ttl   = 1
    },
    {
      id    = "domainkey_no_mail"
      name  = "*._domainkey"
      value = "v=DKIM1; p="
      type  = "TXT"
      ttl   = 1
    },
    {
      id    = "spf1_no_mail"
      name  = "@"
      value = "v=spf1 -all"
      type  = "TXT"
      ttl   = 1
    },
  ]
}

#
# Allow GitHub Webhooks
#
resource "cloudflare_filter" "cf_domain_homelab_github_webhooks" {
  zone_id     = module.cf_domain_homelab.zone_id
  description = "Allow GitHub Webhooks"
  expression = format(
    "(ip.geoip.asnum eq 36459 and http.host eq \"flux-webhook.%s\") or (http.host eq \"arc-webhook.%s\" and ip.geoip.asnum eq 36459)",
    data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"],
    data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"]
  )
}

resource "cloudflare_firewall_rule" "cf_domain_homelab_github_webhooks" {
  zone_id     = module.cf_domain_homelab.zone_id
  description = "Firewall rule to allow GitHub & Webhooks"
  filter_id   = cloudflare_filter.cf_domain_homelab_github_webhooks.id
  action      = "allow"
}

resource "cloudflare_page_rule" "cf_domain_homelab_plex_bypass_cache" {
  zone_id  = module.cf_domain_homelab.zone_id
  target   = format("plex.%s/*", module.cf_domain_homelab.zone)
  status   = "active"
  priority = 1

  actions {
    cache_level         = "bypass"
    disable_performance = true
  }
}
