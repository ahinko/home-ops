terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.11.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
