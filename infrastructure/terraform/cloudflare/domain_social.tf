module "cf_domain_social" {
  source     = "./modules/cf_domain"
  domain     = data.sops_file.cloudflare_secrets.data["cloudflare_domain_social"]
  account_id = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  dns_entries = [
    #    {
    #      id      = "www"
    #      name    = "www"
    #      value   = "ingress.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_social"]}"
    #      type    = "CNAME"
    #      ttl     = 1
    #      proxied = true
    #    },
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

  waf_custom_rules = [
    {
      enabled     = true
      description = "Firewall rule to block bots and threats determined by CF"
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
    },
  ]
}

resource "cloudflare_tunnel" "social" {
  account_id = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  name       = "social"
  secret     = base64encode(data.sops_file.cloudflare_secrets.data["cloudflare_social_tunnel_secret"])
}
