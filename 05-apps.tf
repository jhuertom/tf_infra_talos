###################################################################
# HAProxy Ingress Controller - TALOS CLUSTER
###################################################################

resource "kubernetes_namespace" "haproxy_controller_talos" {
  provider = kubernetes.talos
  metadata {
    name = "haproxy-controller"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "haproxy_ingress_talos" {
  provider   = helm.talos
  name       = "haproxy-ingress"
  repository = "https://haproxytech.github.io/helm-charts"
  chart      = "kubernetes-ingress"
  namespace  = kubernetes_namespace.haproxy_controller_talos.metadata[0].name
  create_namespace = false
  depends_on = [kubernetes_namespace.haproxy_controller_talos]

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

###################################################################
# ArgoCD - DESPLEGADO EN CLUSTER TALOS
###################################################################

resource "helm_release" "argocd_talos" {
  provider   = helm.talos
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs = [
          "--insecure"
        ]
        config = {
          url = "https://${var.argo_hostname}"
        }
      }
      configs = {
        secret = {
          argocdServerAdminPassword = var.argo_admin_password
        }
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "argocd_ingress_talos" {
  provider = kubernetes.talos
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/ingress.class"                = "haproxy"
      "haproxy.org/load-balance"                   = "roundrobin"
      "haproxy.org/check"                          = "true"
      "haproxy.org/check-http"                     = "/healthz"
      "haproxy.org/backend-protocol"               = "http"
      "haproxy.org/server-proto"                   = "h1"
      "haproxy.org/request-set-header"             = <<-EOT
        X-Forwarded-Proto https
        X-Forwarded-Port 443
        X-Forwarded-For %[src]
      EOT
    }
  }

  spec {
    rule {
      host = "${var.argo_hostname}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd_talos]
}
