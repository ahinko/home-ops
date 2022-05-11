
data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "external_dns" {
  name = "ExternalDNS"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"]
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

resource "cloudflare_api_token" "cert_manager" {
  name = "CertManager"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"]
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

resource "cloudflare_api_token" "cloudflare_ddns" {
  name = "DDNS"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["Zone Read"],
      data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"]
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
    "CLOUDFLARE_ZONE_ID"     = lookup(data.cloudflare_zones.domain.zones[0], "id"),
    "CLOUDFLARE_RECORD_NAME" = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
  }
}
