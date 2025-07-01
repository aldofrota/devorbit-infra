terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Módulo para criar namespace e recursos base
module "devorbit_environment" {
  source = "./modules/environment"
  
  namespace_name = var.namespace_name
  hash           = var.hash
  ttl_hours      = var.ttl_hours
}

# Módulo para banco de dados
module "database" {
  source = "./modules/database"
  
  namespace_name = var.namespace_name
  depends_on     = [module.devorbit_environment]
}

# Módulo para Redis
module "redis" {
  source = "./modules/redis"
  
  namespace_name = var.namespace_name
  depends_on     = [module.devorbit_environment]
}

# Módulo para Traefik Ingress Controller
module "traefik" {
  source = "./modules/traefik"
  
  namespace_name = var.namespace_name
  depends_on     = [module.devorbit_environment]
} 