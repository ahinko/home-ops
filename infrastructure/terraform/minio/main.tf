terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.13.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
