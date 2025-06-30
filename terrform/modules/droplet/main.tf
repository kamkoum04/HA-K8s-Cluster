resource "digitalocean_droplet" "this" {
  count     = var.droplet_count
  name      = "${var.name_prefix}-${count.index + 1}"
  region    = var.region
  size      = var.size
  image     = var.image
  ssh_keys  = var.ssh_keys
  tags      = var.tags

  user_data = var.user_data
 
}
