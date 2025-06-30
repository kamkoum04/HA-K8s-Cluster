variable "do_token" {}
variable "ssh_key_name" {}
variable "ssh_pub_key" {}
variable "region" {
  default = "fra1"
}
variable "master_count" {
  default = 3
}
variable "worker_count" {
  default = 2
}
