terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.0.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "minio_secrets.sops.yaml"
}
