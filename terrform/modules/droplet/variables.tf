variable "name_prefix" {}
variable "region" {}
variable "size" {}
variable "image" {}
variable "ssh_keys" {}
variable "tags" {}
variable "droplet_count" {}
variable "user_data" {
  default = null
}
