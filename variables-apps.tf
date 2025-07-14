# Variables
variable "kubeconfig_path" {
  description = "Ruta al archivo kubeconfig (legacy - usar talos_kubeconfig_path)"
  type        = string
  default     = "~/.kube/config"
}

variable "talos_kubeconfig_path" {
  description = "Ruta al archivo kubeconfig del cluster Talos"
  type        = string
  default     = "../../tf_infra_talos/kubeconfig-talos.yaml"
}

variable "rancher_kubeconfig_path" {
  description = "Ruta al archivo kubeconfig del cluster Rancher"
  type        = string
  default     = "../../tf_infra_talos/kubeconfig-rancher.yaml"
}

variable "argo_admin_password" {
  description = "Contraseña para el usuario admin de ArgoCD"
  type        = string
  sensitive   = true
}

variable "argo_hostname" {
  description = "Hostname para ArgoCD"
  type        = string
}

variable "rancher_bootstrap_password" {
  description = "Contraseña inicial para el usuario admin de Rancher"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Nombre del clúster Talos en Rancher"
  type        = string
  default     = "talos-cluster"
}

variable "rancher_version" {
  description = "Versión de Rancher"
  type        = string
}

# Variables para Rancher API
variable "rancher_api_url" {
  description = "URL de la API de Rancher (ej: https://rancher.example.com/v3)"
  type        = string
}

variable "rancher_api_token" {
  description = "Token de API de Rancher para autenticación"
  type        = string
  sensitive   = true
}

variable "rancher_insecure" {
  description = "Permite conexiones TLS inseguras a Rancher"
  type        = bool
  default     = false
}

variable "talos_cluster_description" {
  description = "Descripción del clúster Talos"
  type        = string
  default     = "Clúster Talos importado desde Terraform"
}