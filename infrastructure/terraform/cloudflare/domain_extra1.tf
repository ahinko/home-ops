module "cf_domain_extra1" {
  source     = "./modules/cf_domain"
  domain     = data.sops_file.cloudflare_secrets.data["cloudflare_domain_extra1"]
  account_id = data.sops_file.cloudflare_secrets.data["cloudflare_account_id"]
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
      value   = "protonmail.domainkey.d43abnd2ilgint7l4m2btuhquj5ibbo2pngsy73ohbq5svyzts46a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_2"
      name    = "protonmail2._domainkey"
      value   = "protonmail2.domainkey.d43abnd2ilgint7l4m2btuhquj5ibbo2pngsy73ohbq5svyzts46a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_domainkey_3"
      name    = "protonmail3._domainkey"
      value   = "protonmail3.domainkey.d43abnd2ilgint7l4m2btuhquj5ibbo2pngsy73ohbq5svyzts46a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },

    {
      id    = "protonmail_dmarc"
      name  = "_dmarc"
      value = "v=DMARC1; p=none"
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
      value = "protonmail-verification=3e0315e797bc8ab96c39aac859f619dc013659e3"
      type  = "TXT"
    },
  ]
}
