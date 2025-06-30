output "droplet_ips" {
  value = [for d in digitalocean_droplet.this : d.ipv4_address]
}
