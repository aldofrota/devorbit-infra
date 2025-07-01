resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = var.namespace_name
  create_namespace = false

  set {
    name  = "auth.password"
    value = "devorbit123"
  }

  set {
    name  = "master.persistence.size"
    value = "1Gi"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
} 