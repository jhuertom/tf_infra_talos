output "talos_cluster_endpoint" {
  description = "Endpoint del cluster Talos"
  value       = "https://${var.talos_vms[local.talos_control_plane_key].ip_addr}:6443"
}

output "talos_control_plane_ips" {
  description = "IPs de los nodos control plane"
  value       = [for vm in var.talos_vms : vm.ip_addr if vm.role == "controlplane"]
}

output "talos_worker_ips" {
  description = "IPs de los nodos worker"
  value       = [for vm in var.talos_vms : vm.ip_addr if vm.role == "worker"]
}

output "kubeconfig_file_talos" {
  description = "Ubicación del archivo kubeconfig de Talos"
  value       = "${path.module}/kubeconfig-talos.yaml"
}

output "talos_cluster_status" {
  description = "Estado del cluster Talos"
  value = {
    cluster_name = var.talos_cluster_name
    nodes_total  = length(var.talos_vms)
    control_planes = length([for vm in var.talos_vms : vm if vm.role == "controlplane"])
    workers = length([for vm in var.talos_vms : vm if vm.role == "worker"])
  }
}
