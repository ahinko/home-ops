terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.20.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
