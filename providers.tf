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
  }
}

# Provider configuration
provider "proxmox" {
  endpoint = var.pve_host_address
  username = var.pve_user
  password = var.pve_password
  insecure = true
}