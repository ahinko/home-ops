resource "cloudflare_api_token" "cert_manager" {
  name = "CertManager"

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

resource "kubernetes_secret" "cert_manager_token" {
  metadata {
    name      = "cert-manager-cloudflare-api-key"
    namespace = "cert-manager"
  }

  data = {
    "cloudflare-api-token" = cloudflare_api_token.cert_manager.value
  }
}
