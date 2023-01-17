terraform {
  cloud {
    organization = "my-homelab"
    workspaces {
      name = "homelab-minio"
    }
  }
}
