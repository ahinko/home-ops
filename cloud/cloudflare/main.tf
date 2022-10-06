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
      version = "3.24.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.14.0"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "sops.secrets.yaml"
}

provider "cloudflare" {
  api_token = data.sops_file.cloudflare_secrets.data["cloudflare_api_token"]
}

provider "kubernetes" {
  config_path    = "~/.kube/configs/metal"
  config_context = "metal"
}

data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}
