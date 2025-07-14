terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "~> 0.69"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.5.0"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.9"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 7.0"
    }
  }
}

# Provider configuration
provider "proxmox" {
  endpoint = var.pve_host_address
  username = var.pve_user
  password = var.pve_password
  insecure = true
}

# Provider para Talos Cluster
provider "helm" {
  alias = "talos"
  kubernetes {
    config_path = local_file.kubeconfig_cluster.filename
  }
}

provider "kubernetes" {
  alias       = "talos" 
  config_path = local_file.kubeconfig_cluster.filename
}

# Provider para Rancher Cluster
provider "helm" {
  alias = "rancher"
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

provider "kubernetes" {
  alias       = "rancher"
  config_path = local_file.kubeconfig.filename
}

# Provider para Rancher con configuración inicial (sin autenticación)
provider "rancher2" {
  alias     = "bootstrap"
  api_url   = var.rancher_api_url
  bootstrap = true
  insecure  = var.rancher_insecure
  timeout   = "300s"  # Timeout de 5 minutos para operaciones de bootstrap
}

# Provider principal de Rancher con el token generado
provider "rancher2" {
  alias     = "admin"
  api_url   = var.rancher_api_url
  token_key = rancher2_token.admin_token.token
  insecure  = var.rancher_insecure
  timeout   = "300s"  # Timeout de 5 minutos para operaciones
}