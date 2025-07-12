# Crear VM clonando la plantilla
resource "proxmox_virtual_environment_vm" "docker_services" {
  name        = var.haproxy_vm_name
  description = "VM HAProxy"
  tags        = ["terraform", "docker", "haproxy"]
  node_name   = var.haproxy_proxmox_node
  vm_id       = var.haproxy_vm_id

  # Clonar desde plantilla
  clone {
    vm_id = var.haproxy_vm_template_id
  }

  # Configuración de CPU y memoria
  cpu {
    cores = var.haproxy_vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.haproxy_vm_memory
  }

  disk {
    datastore_id = "local"
    file_id      = null
    interface    = "virtio0"
    size         = var.haproxy_vm_disk_size
  }

  # Configuración de red
  network_device {
    bridge = var.haproxy_vm_network_bridge
  }

  # Configuración de Cloud-Init
  initialization {
    datastore_id = "local"
    ip_config {
      ipv4 {
        address = "${var.haproxy_vm_ip}/23"
        gateway = "${var.haproxy_vm_gateway}"
      }
    }
    user_account {
      keys     = []
      password = "${var.haproxy_ssh_password}"
      username = "${var.haproxy_ssh_user}"
    }
  }
  agent {
    enabled = true
  }
  startup {
    order      = 1
    up_delay   = 30
    down_delay = 60
  }

  # Provisioning para configurar los servicios Docker
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/docker-services/certs",
      "sudo mkdir -p /etc/letsencrypt",
      "sudo chown -R ${var.haproxy_ssh_user}:${var.haproxy_ssh_user} /opt/docker-services",
      "sudo chown -R ${var.haproxy_ssh_user}:${var.haproxy_ssh_user} /etc/letsencrypt",
      "echo 'dns_cloudflare_api_token = ${var.dns_cloudflare_api_token}' > /etc/letsencrypt/cloudflare.ini",
      "sudo chmod 600 /etc/letsencrypt/cloudflare.ini"
    ]

    connection {
      type     = "ssh"
      user     = "${var.haproxy_ssh_user}"
      password = "${var.haproxy_ssh_password}"
      host     = "${var.haproxy_vm_ip}"
      timeout  = "5m"
    }
  }

  # Copiar archivos de configuración
  provisioner "file" {
    content = templatefile("${path.module}/templates/docker-compose-haproxy.yml.tpl", {
      domain = var.domain
      cloudflare_email = var.cloudflare_email
      dns_cloudflare_api_token = var.dns_cloudflare_api_token
    })
    destination = "/opt/docker-services/docker-compose.yml"

    connection {
      type     = "ssh"
      user     = "${var.haproxy_ssh_user}"
      password = "${var.haproxy_ssh_password}"
      host     = "${var.haproxy_vm_ip}"
    }
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/haproxy.cfg.tpl", {
      domain = var.domain
      stats_port = var.stats_port
      rancher_hostname = var.rancher_hostname
      rancher_host = var.rancher_host
      rancher_http_port = var.rancher_http_port
      rancher_https_port = var.rancher_https_port
      talos_servers = var.talos_servers
    })
    destination = "/opt/docker-services/haproxy.cfg"

    connection {
      type     = "ssh"
      user     = "${var.haproxy_ssh_user}"
      password = "${var.haproxy_ssh_password}"
      host     = "${var.haproxy_vm_ip}"
    }
  }

  # Generar el certificado SSL con Certbot e iniciar haproxy
  provisioner "remote-exec" {
    inline = [
      "cd /opt/docker-services",
      "docker compose pull",
      "docker compose up dns-cloudflare",
      "sudo cat /etc/letsencrypt/live/${var.domain}/privkey.pem /etc/letsencrypt/live/${var.domain}/fullchain.pem | sudo tee /opt/docker-services/certs/${var.domain}.pem",
      "sudo chown ${var.haproxy_ssh_user}:${var.haproxy_ssh_user} /opt/docker-services/certs/${var.domain}.pem",
      "docker compose up haproxy -d",
      "sleep 10",
      "docker compose ps"
    ]

    connection {
      type     = "ssh"
      user     = "${var.haproxy_ssh_user}"
      password = "${var.haproxy_ssh_password}"
      host     = "${var.haproxy_vm_ip}"
    }
  }
}