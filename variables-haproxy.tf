variable "haproxy_proxmox_node" {
  description = "Nodo de Proxmox"
  type        = string
  default     = "proxmox-node"
}

variable "haproxy_vm_name" {
  description = "Nombre de la VM a crear"
  type        = string
  default     = "docker-services"
}

variable "haproxy_vm_id" {
  description = "ID de la VM"
  type        = number
  default     = 600
}

variable "haproxy_vm_template_id" {
  description = "ID de la plantilla de la VM"
  type        = number
  default     = 900
}

variable "cloudflare_email" {
  description = "Email para certificados SSL"
  type        = string
}

variable "domain" {
  description = "Dominio principal"
  type        = string
}

variable "dns_cloudflare_api_token" {
  description = "API Token de Cloudflare"
  type        = string
  sensitive   = true
}

variable "stats_port" {
  description = "Puerto para las estadísticas de HAProxy"
  type        = number
  default     = 8404
}

variable "rancher_hostname" {
  description = "Hostname para Rancher"
  type        = string
}

variable "rancher_host" {
  description = "IP del servidor Rancher"
  type        = string
}

variable "rancher_http_port" {
  description = "Puerto HTTP de Rancher"
  type        = number
}

variable "rancher_https_port" {
  description = "Puerto HTTPS de Rancher"
  type        = number
}

variable "talos_servers" {
  description = "Lista de servidores Talos"
  type = list(object({
    ip   = string
    port = number
  }))
}
variable "haproxy_ssh_user" {
  description = "Usuario SSH para la VM de HAProxy"
  type        = string
}
variable "haproxy_ssh_password" {
  description = "Contraseña SSH para la VM de HAProxy"
  type        = string
  sensitive   = true
}
variable "haproxy_vm_ip" {
  description = "IP de la VM de HAProxy"
  type        = string
}
variable "haproxy_vm_gateway" {
  description = "Gateway de la VM de HAProxy"
  type        = string
}

variable "haproxy_vm_cpu_cores" {
  description = "Número de núcleos de CPU para la VM de HAProxy"
  type        = number
  default     = 2
}

variable "haproxy_vm_memory" {
  description = "Memoria RAM para la VM de HAProxy (en MB)"
  type        = number
  default     = 2048
}

variable "haproxy_vm_disk_size" {
  description = "Tamaño del disco para la VM de HAProxy (en GB)"
  type        = string
  default     = "20G"
}

variable "haproxy_vm_network_bridge" {
  description = "Puente de red para la VM de HAProxy"
  type        = string
  default     = "vmbr0"
}