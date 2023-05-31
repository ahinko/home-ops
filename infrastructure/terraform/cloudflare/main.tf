terraform {
  cloud {
    organization = "my-homelab"
    workspaces {
      name = "homelab-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.7.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

# Read secrets
data "sops_file" "cloudflare_secrets" {
  source_file = "cloudflare_secrets.sops.yaml"
}

# Obtain current home IP address
data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_api_token_permission_groups" "all" {}

data "cloudflare_zones" "homelab" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain_homelab"]
  }
}
