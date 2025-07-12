###################################################
# DOWNLOAD TALOS IMAGE
###################################################

# Local para obtener la clave del primer control plane
locals {
  rancher_control_plane_key = [for k, v in var.rancher_vms : k if v.role == "controlplane"][0]
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each                = toset(var.rancher_proxmox_nodes)
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = each.key
  file_name               = "talos-${var.talos_version}-nocloud-amd64-rancher.img"
  url                     = "https://factory.talos.dev/image/787b79bb847a07ebb9ae37396d015617266b1cef861107eaec85968ad7b40618/${var.talos_version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = true
}

###################################################
# VM CREATE
###################################################
resource "proxmox_virtual_environment_vm" "rancher" {
  for_each    = var.rancher_vms

  name        = each.value.name
  description = "Managed by Terraform - Rancher Management Cluster"
  tags        = ["terraform", "rancher", "management"]
  node_name   = each.value.node
  on_boot     = true

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image[each.value.node].id
    file_format  = "raw"
    interface    = "virtio0"
    size         = each.value.disk_size
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local"
    dns {
      domain  = "rancher.local"
      servers = split(",", var.rancher_dns)
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip_addr}/23"
        gateway = var.rancher_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

###################################################
# CLUSTER CREATION
###################################################
resource "talos_machine_secrets" "machine_secrets" {
  depends_on = [time_sleep.wait_for_vms]
}

# Agregar un recurso de espera para asegurar que las VMs estén listas
resource "time_sleep" "wait_for_vms" {
  depends_on = [proxmox_virtual_environment_vm.rancher]
  create_duration = "30s"
}

data "talos_client_configuration" "talosconfig" {
  depends_on           = [talos_machine_secrets.machine_secrets]
  cluster_name         = var.rancher_cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for vm in var.rancher_vms : vm.ip_addr if vm.role == "controlplane"]
}

data "talos_machine_configuration" "machineconfig" {
  for_each = var.rancher_vms

  depends_on       = [talos_machine_secrets.machine_secrets]
  cluster_name     = var.rancher_cluster_name
  cluster_endpoint = "https://${var.rancher_vms[local.rancher_control_plane_key].ip_addr}:6443"
  machine_type     = each.value.role
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "apply" {
  for_each = var.rancher_vms

  depends_on = [
    proxmox_virtual_environment_vm.rancher,
    time_sleep.wait_for_vms
  ]

  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig[each.key].machine_configuration
  node                        = each.value.ip_addr
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.rancher_vms[local.rancher_control_plane_key].ip_addr
}

data "talos_cluster_health" "health" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = [for vm in var.rancher_vms : vm.ip_addr if vm.role == "controlplane"]
  worker_nodes         = [for vm in var.rancher_vms : vm.ip_addr if vm.role == "worker"]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.rancher_vms[local.rancher_control_plane_key].ip_addr
}

resource "local_file" "kubeconfig" {
  depends_on = [data.talos_cluster_kubeconfig.kubeconfig]
  content    = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename   = "${path.module}/kubeconfig-rancher.yaml"
}
