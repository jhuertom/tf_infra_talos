###################################################
# TALOS CLUSTER VARIABLES
###################################################
variable "talos_proxmox_nodes" {
  description = "Lista de nodos Proxmox donde crear las VMs"
  type        = list(string)
}

variable "talos_gateway" {
  description = "Gateway para la red Talos"
  type        = string
}

variable "talos_dns" {
  description = "Servidor DNS para Talos"
  type        = string
}

variable "talos_cluster_name" {
  description = "Nombre del cluster Talos"
  type        = string
}

variable "talos_vms" {
  description = "Configuración de las VMs del cluster Talos"
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
