provider "sops" {}

provider "minio" {
  alias          = "nas"
  minio_server   = data.sops_file.minio_secrets.data["minio_server_external"]
  minio_user     = data.sops_file.minio_secrets.data["minio_username"]
  minio_password = data.sops_file.minio_secrets.data["minio_password"]
  minio_ssl      = true
}

provider "kubernetes" {
  config_path    = "~/.kube/configs/metal"
  config_context = "metal"
}
