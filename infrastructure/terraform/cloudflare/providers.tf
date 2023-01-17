provider "sops" {}

provider "cloudflare" {
  api_token = data.sops_file.cloudflare_secrets.data["cloudflare_api_token"]
}

provider "kubernetes" {
  config_path    = "~/.kube/configs/metal"
  config_context = "metal"
}
