terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.15.1"
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

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
