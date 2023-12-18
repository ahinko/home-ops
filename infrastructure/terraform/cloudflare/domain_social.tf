module "cf_domain_social" {
  source     = "./modules/cf_domain"
  domain     = data.sops_file.cloudflare_secrets.data["cloudflare_domain_social"]
  account_id = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  dns_entries = [
    {
      id    = "protonmail_verification"
      name  = "@"
      value = "protonmail-verification=8d67a77d13d966d68ecc2ccbf583e5a015ff1d08"
      type  = "TXT"
    },
    {
      id       = "protonmail_mx_1"
      name     = "@"
      priority = 10
      value    = "mail.protonmail.ch"
      type     = "MX"
    },
    {
      id       = "protonmail_mx_2"
      name     = "@"
      priority = 20
      value    = "mailsec.protonmail.ch"
      type     = "MX"
    },
    {
      id    = "protonmail_spf1"
      name  = "@"
      value = "v=spf1 include:_spf.protonmail.ch mx ~all"
      type  = "TXT"
    },
    {
      id      = "protonmail_domainkey_1"
      name    = "protonmail._domainkey"
      value   = "protonmail.domainkey.dv2agox7wmym2m3i5quivyz3gb5ujsptc25jz7d2ewhgogsfmxkua.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_2"
      name    = "protonmail2._domainkey"
      value   = "protonmail2.domainkey.dv2agox7wmym2m3i5quivyz3gb5ujsptc25jz7d2ewhgogsfmxkua.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_3"
      name    = "protonmail3._domainkey"
      value   = "protonmail3.domainkey.dv2agox7wmym2m3i5quivyz3gb5ujsptc25jz7d2ewhgogsfmxkua.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id    = "protonmail_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=none"
      type  = "TXT"
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
