# Variables
variable "pve_host_address" {
  description = "URL del API de Proxmox"
  type        = string
  default     = "https://your-proxmox-server:8006/api2/json"
}

variable "pve_user" {
  description = "Usuario de Proxmox"
  type        = string
  default     = "root@pam"
}

variable "pve_password" {
  description = "Contraseña de Proxmox"
  type        = string
  sensitive   = true
}

variable "talos_version" {
  description = "Versión de Talos a instalar"
  type        = string
  default     = "v1.4.0"
}