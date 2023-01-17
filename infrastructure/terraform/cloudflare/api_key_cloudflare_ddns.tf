resource "cloudflare_api_token" "cloudflare_ddns" {
  name = "DDNS"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"]
    ]
    resources = {
      "com.cloudflare.api.account.zone.*" = "*"
    }
  }
}

resource "kubernetes_secret" "cloudflare_ddns_token" {
  metadata {
    name      = "cloudflare-ddns"
    namespace = "networking"
  }

  data = {
    "CLOUDFLARE_API_TOKEN"   = cloudflare_api_token.cloudflare_ddns.value,
    "CLOUDFLARE_ZONE_ID"     = lookup(data.cloudflare_zones.homelab.zones[0], "id"),
    "CLOUDFLARE_RECORD_NAME" = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"]}"
  }
}
