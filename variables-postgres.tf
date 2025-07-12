# PostgreSQL VM Variables
variable "postgres_proxmox_node" {
  description = "Nodo de Proxmox para PostgreSQL"
  type        = string
  default     = "proxmox-node"
}

variable "postgres_vm_name" {
  description = "Nombre de la VM de PostgreSQL"
  type        = string
  default     = "postgres-server"
}

variable "postgres_vm_id" {
  description = "ID de la VM de PostgreSQL"
  type        = number
  default     = 601
}

variable "postgres_vm_template_id" {
  description = "ID de la plantilla para PostgreSQL"
  type        = number
  default     = 900
}

variable "postgres_ssh_user" {
  description = "Usuario SSH para la VM de PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "postgres_ssh_password" {
  description = "Contraseña SSH para la VM de PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_vm_ip" {
  description = "IP de la VM de PostgreSQL"
  type        = string
}

variable "postgres_vm_gateway" {
  description = "Gateway de la VM de PostgreSQL"
  type        = string
}

variable "postgres_vm_cpu_cores" {
  description = "Número de núcleos de CPU para PostgreSQL"
  type        = number
  default     = 4
}

variable "postgres_vm_memory" {
  description = "Memoria RAM para PostgreSQL (en MB)"
  type        = number
  default     = 4096
}

variable "postgres_vm_disk_size" {
  description = "Tamaño del disco para PostgreSQL (en GB)"
  type        = string
  default     = "50G"
}

variable "postgres_vm_network_bridge" {
  description = "Puente de red para la VM de PostgreSQL"
  type        = string
  default     = "vmbr0"
}

# PostgreSQL Database Configuration
variable "postgres_root_password" {
  description = "Contraseña del usuario postgres (superuser)"
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
  default     = "appdb"
}

variable "postgres_app_user" {
  description = "Usuario de aplicación para PostgreSQL"
  type        = string
  default     = "appuser"
}

variable "postgres_app_password" {
  description = "Contraseña del usuario de aplicación"
  type        = string
  sensitive   = true
}

variable "postgres_port" {
  description = "Puerto de PostgreSQL"
  type        = number
  default     = 5432
}

variable "postgres_version" {
  description = "Versión de PostgreSQL a instalar"
  type        = string
  default     = "16"
}

variable "postgres_enable_external_access" {
  description = "Habilitar acceso externo a PostgreSQL via NodePort"
  type        = bool
  default     = false
}

variable "postgres_nodeport" {
  description = "Puerto NodePort para acceso externo a PostgreSQL"
  type        = number
  default     = 30432
}