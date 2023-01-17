resource "cloudflare_api_token" "external_dns" {
  name = "ExternalDNS"

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

resource "kubernetes_secret" "external_dns_token" {
  metadata {
    name      = "external-dns-cloudflare-api-key"
    namespace = "networking"
  }

  data = {
    "cloudflare_api_token" = cloudflare_api_token.external_dns.value
  }
}
