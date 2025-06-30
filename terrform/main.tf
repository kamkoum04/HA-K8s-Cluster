module "lb" {
  source         = "./modules/droplet"
  name_prefix    = "k8s-lb"
  region         = var.region
  size           = "s-1vcpu-1gb"
  image          = "ubuntu-24-10-x64"
  ssh_keys       = [digitalocean_ssh_key.default.id]
  tags           = ["k8s", "lb"]
  droplet_count  = 1  
  providers = {
    digitalocean = digitalocean
  }
}


module "masters" {
  source         = "./modules/droplet"
  name_prefix    = "k8s-master"
  region         = var.region
  size           = "s-2vcpu-2gb"
  image          = "ubuntu-24-10-x64"
  ssh_keys       = [digitalocean_ssh_key.default.id]
  tags           = ["k8s", "master"]
  droplet_count  = var.master_count  # ✅
  providers = {
    digitalocean = digitalocean
  }
}

module "workers" {
  source         = "./modules/droplet"
  name_prefix    = "k8s-worker"
  region         = var.region
  size           = "s-2vcpu-2gb"
  image          = "ubuntu-24-10-x64"
  ssh_keys       = [digitalocean_ssh_key.default.id]
  tags           = ["k8s", "worker"]
  droplet_count  = var.worker_count  # ✅
  providers = {
    digitalocean = digitalocean
  }
}


