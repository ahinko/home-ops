terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "1.15.3"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
