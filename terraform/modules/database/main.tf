resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = var.namespace_name
  create_namespace = false

  set {
    name  = "auth.postgresPassword"
    value = "devorbit123"
  }

  set {
    name  = "auth.database"
    value = "devorbit"
  }

  set {
    name  = "primary.persistence.size"
    value = "1Gi"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
} 