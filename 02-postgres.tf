# Crear VM de PostgreSQL
resource "proxmox_virtual_environment_vm" "postgres_server" {
  name        = var.postgres_vm_name
  description = "VM PostgreSQL 16 with Docker"
  tags        = ["terraform", "docker", "postgresql"]
  node_name   = var.postgres_proxmox_node
  vm_id       = var.postgres_vm_id

  # Clonar desde plantilla
  clone {
    vm_id = var.postgres_vm_template_id
  }

  # Configuración de CPU y memoria
  cpu {
    cores = var.postgres_vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.postgres_vm_memory
  }

  disk {
    datastore_id = "local"
    file_id      = null
    interface    = "virtio0"
    size         = var.postgres_vm_disk_size
  }

  # Configuración de red
  network_device {
    bridge = var.postgres_vm_network_bridge
  }

  # Configuración de Cloud-Init
  initialization {
    datastore_id = "local"
    ip_config {
      ipv4 {
        address = "${var.postgres_vm_ip}/23"
        gateway = "${var.postgres_vm_gateway}"
      }
    }
    user_account {
      keys     = []
      password = "${var.postgres_ssh_password}"
      username = "${var.postgres_ssh_user}"
    }
  }

  agent {
    enabled = true
  }

  startup {
    order      = 2
    up_delay   = 45
    down_delay = 60
  }

  # Provisioning para preparar directorios Docker
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/postgres-docker/data /opt/postgres-docker/init-scripts /opt/postgres-docker/config",
      "sudo chown -R ${var.postgres_ssh_user}:${var.postgres_ssh_user} /opt/postgres-docker",
      "chmod 755 /opt/postgres-docker"
    ]

    connection {
      type     = "ssh"
      user     = "${var.postgres_ssh_user}"
      password = "${var.postgres_ssh_password}"
      host     = "${var.postgres_vm_ip}"
      timeout  = "5m"
    }
  }

  # Copiar archivos de configuración
  provisioner "file" {
    content = templatefile("${path.module}/templates/docker-compose-postgres.yml.tpl", {
      postgres_version = var.postgres_version
      postgres_port = var.postgres_port
      database_name = var.postgres_database_name
      postgres_root_password = var.postgres_root_password
    })
    destination = "/opt/postgres-docker/docker-compose.yml"

    connection {
      type     = "ssh"
      user     = "${var.postgres_ssh_user}"
      password = "${var.postgres_ssh_password}"
      host     = "${var.postgres_vm_ip}"
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/postgresql.conf.tpl", {
      postgres_port = var.postgres_port
    })
    destination = "/opt/postgres-docker/config/postgresql.conf"

    connection {
      type     = "ssh"
      user     = "${var.postgres_ssh_user}"
      password = "${var.postgres_ssh_password}"
      host     = "${var.postgres_vm_ip}"
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/init-postgres.sh.tpl", {
      database_name = var.postgres_database_name
      app_user = var.postgres_app_user
      app_password = var.postgres_app_password
    })
    destination = "/opt/postgres-docker/init-scripts/01-init.sh"

    connection {
      type     = "ssh"
      user     = "${var.postgres_ssh_user}"
      password = "${var.postgres_ssh_password}"
      host     = "${var.postgres_vm_ip}"
    }
  }

  # Iniciar contenedores PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "cd /opt/postgres-docker",
      "chmod +x init-scripts/01-init.sh",
      "docker compose pull postgres",
      "docker compose up postgres -d"
    ]

    connection {
      type     = "ssh"
      user     = "${var.postgres_ssh_user}"
      password = "${var.postgres_ssh_password}"
      host     = "${var.postgres_vm_ip}"
      timeout  = "15m"
    }
  }
}