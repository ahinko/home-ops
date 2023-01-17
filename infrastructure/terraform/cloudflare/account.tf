resource "cloudflare_account" "ahinko" {
  name              = "My Homelab"
  type              = "standard"
  enforce_twofactor = true
}
