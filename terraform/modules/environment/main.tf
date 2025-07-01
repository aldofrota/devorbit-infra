resource "kubernetes_namespace" "devorbit" {
  metadata {
    name = var.namespace_name
    labels = {
      "devorbit/hash" = var.hash
      "devorbit/ttl"  = var.ttl_hours
      "devorbit/created-at" = timestamp()
    }
  }
}

resource "kubernetes_config_map" "environment_config" {
  metadata {
    name      = "environment-config"
    namespace = kubernetes_namespace.devorbit.metadata[0].name
  }

  data = {
    HASH           = var.hash
    DOMAIN_SUFFIX  = var.domain_suffix
    TTL_HOURS      = var.ttl_hours
    ENVIRONMENT    = "staging"
  }
} 