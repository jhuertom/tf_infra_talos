# Generar ID único para el clúster
resource "random_id" "cluster_id" {
  byte_length = 8
}

# ============================================================================
# INSTALACIÓN DE RANCHER
# ============================================================================

resource "helm_release" "cert_manager" {
  provider   = helm.rancher
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }
}

resource "helm_release" "rancher" {
  provider = helm.rancher
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  version    = var.rancher_version
  namespace  = "cattle-system"
  create_namespace = true

  depends_on = [helm_release.cert_manager]

  set {
    name  = "agentTLSMode"
    value = "system-store"
  }
  
  values = [
    yamlencode({
      hostname = var.rancher_hostname
      bootstrapPassword = var.rancher_bootstrap_password
      
      ingress = {
        enabled = false
      }
      
      tls = "external"
      replicas = 3
      
      resources = {
        requests = {
          cpu    = "500m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
      }
      
      systemDefaultRegistry = ""
      useBundledSystemChart = false
      antiAffinity = "preferred"
      
      extraEnv = [
        {
          name = "CATTLE_TLS_MIN_VERSION"
          value = "1.2"
        }
      ]
    })
  ]

  timeout = 600
  wait = true
  wait_for_jobs = true
}

resource "kubernetes_namespace" "haproxy_controller" {
  provider = kubernetes.rancher
  metadata {
    name = "haproxy-controller"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "haproxy_ingress" {
  provider   = helm.rancher
  name       = "haproxy-ingress"
  repository = "https://haproxytech.github.io/helm-charts"
  chart      = "kubernetes-ingress"
  namespace  = kubernetes_namespace.haproxy_controller.metadata[0].name
  create_namespace = false
  depends_on = [helm_release.rancher, kubernetes_namespace.haproxy_controller]

  set {
    name  = "controller.service.nodePorts.http"
    value = 32757
  }

  set {
    name  = "controller.service.nodePorts.https"
    value = 30417
  }

  set {
    name  = "controller.service.nodePorts.stat"
    value = 30958
  }

  set {
    name  = "controller.service.nodePorts.prometheus"
    value = 30003
  }

  timeout = 300
  wait = true
}

resource "kubernetes_ingress_v1" "rancher_ingress" {
  provider = kubernetes.rancher
  metadata {
    name      = "rancher-ingress"
    namespace = "cattle-system"
    annotations = {
      "kubernetes.io/ingress.class"    = "haproxy"
      "haproxy.org/load-balance"       = "roundrobin"
      "haproxy.org/check"              = "true"
      "haproxy.org/check-http"         = "/ping"
      "haproxy.org/request-set-header" = <<-EOT
        X-Forwarded-Proto https
        X-Forwarded-Port 443
        X-Forwarded-For %[src]
      EOT
    }
  }

  spec {
    rule {
      host = var.rancher_hostname
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "rancher"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.rancher]
}

resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap
  # Esperar a que Rancher esté desplegado y accesible vía Ingress
  depends_on = [helm_release.rancher, kubernetes_ingress_v1.rancher_ingress]
  initial_password = var.rancher_bootstrap_password
  password = var.rancher_bootstrap_password
}

resource "rancher2_token" "admin_token" {
  provider    = rancher2.bootstrap
  depends_on  = [rancher2_bootstrap.admin]
  
  description = "Admin token for Terraform"
  ttl         = 0  # No expira
}

# ============================================================================
# IMPORTACIÓN DEL CLÚSTER TALOS
# ============================================================================

# Crear el clúster en Rancher usando rancher2_cluster (v1)
resource "rancher2_cluster" "talos_cluster" {
  provider = rancher2.admin
  depends_on = [rancher2_token.admin_token]
  
  name        = var.cluster_name
  description = "Clúster Talos importado vía Terraform"
  
  # Sin configuración RKE - esto indica que es un cluster importado
}

# Crear namespace cattle-system en Talos
resource "kubernetes_namespace" "cattle_system" {
  provider = kubernetes.talos
  metadata {
    name = "cattle-system"
  }
}

# Crear el secreto para el agente cattle en Talos
resource "kubernetes_secret" "cattle_credentials" {
  provider = kubernetes.talos
  metadata {
    name      = "cattle-credentials-${random_id.cluster_id.hex}"
    namespace = "cattle-system"
  }
  
  data = {
    token = rancher2_cluster.talos_cluster.cluster_registration_token.0.token
    url   = "https://${var.rancher_hostname}"
  }
  
  type = "Opaque"
  
  depends_on = [kubernetes_namespace.cattle_system]
}

# ServiceAccount para el cattle-cluster-agent
resource "kubernetes_service_account" "cattle_cluster_agent" {
  provider = kubernetes.talos
  metadata {
    name      = "cattle"
    namespace = "cattle-system"
  }
  
  depends_on = [kubernetes_namespace.cattle_system]
}

# ClusterRole para el cattle-cluster-agent
resource "kubernetes_cluster_role" "cattle_cluster_agent" {
  provider = kubernetes.talos
  metadata {
    name = "cattle"
  }
  
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  
  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

# ClusterRoleBinding para el cattle-cluster-agent
resource "kubernetes_cluster_role_binding" "cattle_cluster_agent" {
  provider = kubernetes.talos
  metadata {
    name = "cattle"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cattle"
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = "cattle"
    namespace = "cattle-system"
  }
  
  depends_on = [
    kubernetes_cluster_role.cattle_cluster_agent,
    kubernetes_service_account.cattle_cluster_agent
  ]
}

# Deployment del cattle-cluster-agent
resource "kubernetes_deployment" "cattle_cluster_agent" {
  provider = kubernetes.talos
  metadata {
    name      = "cattle-cluster-agent"
    namespace = "cattle-system"
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "cattle-cluster-agent"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "cattle-cluster-agent"
        }
      }
      
      spec {
        service_account_name = "cattle"
        
        container {
          name  = "cluster-agent"
          image = "rancher/rancher-agent:v${var.rancher_version}"
          
          env {
            name  = "CATTLE_SERVER"
            value = "https://${var.rancher_hostname}"
          }
          
          env {
            name = "CATTLE_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.cattle_credentials.metadata.0.name
                key  = "token"
              }
            }
          }
          
          env {
            name  = "CATTLE_CLUSTER"
            value = "true"
          }
          
          env {
            name = "CATTLE_CA_CHECKSUM"
            value = ""
          }
          
          volume_mount {
            name       = "cattle-credentials"
            mount_path = "/cattle-credentials"
            read_only  = true
          }
        }
        
        volume {
          name = "cattle-credentials"
          secret {
            secret_name = kubernetes_secret.cattle_credentials.metadata.0.name
          }
        }
        
        # Tolerancias para nodos control plane de Talos
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
        
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
        
        # Tolerancia específica para Talos
        toleration {
          key      = "node.kubernetes.io/not-ready"
          operator = "Exists"
          effect   = "NoExecute"
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_cluster_role_binding.cattle_cluster_agent,
    kubernetes_secret.cattle_credentials
  ]
}
