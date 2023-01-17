module "cf_domain_family" {
  source                        = "./modules/cf_domain"
  domain                        = data.sops_file.cloudflare_secrets.data["cloudflare_domain_family"]
  account_id                    = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
  enable_default_firewall_rules = false
  dns_entries = [
    # E-mail settings
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
      id      = "protonmail_domainkey_1"
      name    = "protonmail._domainkey"
      value   = "protonmail.domainkey.dot77yhappjjwrvwwgf3nm6hs5qt2p4ngn5i2a5qcclbwli4zl3hq.domains.proton.ch"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_2"
      name    = "protonmail2._domainkey"
      value   = "protonmail2.domainkey.dot77yhappjjwrvwwgf3nm6hs5qt2p4ngn5i2a5qcclbwli4zl3hq.domains.proton.ch"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_3"
      name    = "protonmail3._domainkey"
      value   = "protonmail3.domainkey.dot77yhappjjwrvwwgf3nm6hs5qt2p4ngn5i2a5qcclbwli4zl3hq.domains.proton.ch"
      type    = "CNAME"
      proxied = false
    },

    {
      id    = "protonmail_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=quarantine"
      type  = "TXT"
    },
    {
      id    = "protonmail_spf1"
      name  = "@"
      value = "v=spf1 include:_spf.protonmail.ch mx ~all"
      type  = "TXT"
    },
    {
      id    = "protonmail_verification"
      name  = "@"
      value = "protonmail-verification=8bf5c74551bebb8d7c73572b509a69a49aa7e903"
      type  = "TXT"
    },
  ]
}
