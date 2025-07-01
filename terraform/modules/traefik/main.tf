resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = var.namespace_name
  create_namespace = false

  set {
    name  = "ingressRoute.dashboard.enabled"
    value = "true"
  }

  set {
    name  = "ports.websecure.tls.enabled"
    value = "false"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
} 