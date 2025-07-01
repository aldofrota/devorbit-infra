resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = var.namespace_name
  create_namespace = false

  set {
    name  = "auth.mongodbPassword"
    value = "devorbit123"
  }

  set {
    name  = "auth.mongodbDatabase"
    value = "devorbit"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = "1Gi"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.port"
    value = "27017"
  }
} 