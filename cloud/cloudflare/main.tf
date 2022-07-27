terraform {

  backend "remote" {
    organization = "my-homelab"
    workspaces {
      name = "homelab-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.20.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.0.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "sops.secrets.yaml"
}

provider "cloudflare" {
  email     = data.sops_file.cloudflare_secrets.data["cloudflare_email"]
  api_token = data.sops_file.cloudflare_secrets.data["cloudflare_api_token"]
}

provider "kubernetes" {
  config_path    = "~/.kube/configs/old"
  config_context = "old"
}

data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}
