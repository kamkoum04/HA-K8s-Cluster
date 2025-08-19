terraform {
  backend "remote" {
    organization = "my-k8s-org"

    workspaces {
      name = "k8s-ha-cluster"
    }

  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean" 
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token

}

