###################################################
# RANCHER MANAGEMENT CLUSTER CONFIGURATION
###################################################
variable "rancher_proxmox_nodes" {
  type = list(string)
}
variable "rancher_vms" {
  type = map(object({
    name      = string
    role      = string
    node      = string
    ip_addr   = string
    cores     = number
    memory    = number
    disk_size = number
  }))
}
variable "rancher_gateway" {
  type    = string
}
variable "rancher_dns" {
  type    = string
}
variable "rancher_cluster_name" {
  type    = string
}