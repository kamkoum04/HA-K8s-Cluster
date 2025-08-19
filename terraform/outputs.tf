output "lb_ip" {
  value = module.lb.droplet_ips[0]
}

output "master_ips" {
  value = module.masters.droplet_ips
}

output "worker_ips" {
  value = module.workers.droplet_ips
}
