#
# GeoIP blocking
#
resource "cloudflare_filter" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to block all countries except SE"
  expression  = "(ip.geoip.country ne \"SE\")"
}
resource "cloudflare_firewall_rule" "countries" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to block all countries except SE"
  filter_id   = cloudflare_filter.countries.id
  action      = "block"
}


#
# Allow GitHub flux API
#
resource "cloudflare_filter" "github_flux_api" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to allow GitHub Flux API"
  expression = format(
    "(ip.geoip.asnum eq 36459 and http.host eq \"flux-webhook.%s\")",
    data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  )
}

resource "cloudflare_firewall_rule" "github_flux_api" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to allow GitHub Flux API"
  filter_id   = cloudflare_filter.github_flux_api.id
  action      = "allow"
}

#
# Bots
#
resource "cloudflare_filter" "bots" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to block bots determined by CF"
  expression  = "(cf.client.bot)"
}
resource "cloudflare_firewall_rule" "bots" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to block bots determined by CF"
  filter_id   = cloudflare_filter.bots.id
  action      = "block"
}

#
# Block threats less than Medium
#
resource "cloudflare_filter" "threats" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Expression to block medium threats"
  expression  = "(cf.threat_score gt 14)"
}
resource "cloudflare_firewall_rule" "threats" {
  zone_id     = lookup(data.cloudflare_zones.domain.zones[0], "id")
  description = "Firewall rule to block medium threats"
  filter_id   = cloudflare_filter.threats.id
  action      = "block"
}
