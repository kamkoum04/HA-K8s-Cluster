resource "digitalocean_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = var.ssh_pub_key

}