terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"   # ✅ MUST match the root module
      version = "~> 2.0"
    }
  }
}
