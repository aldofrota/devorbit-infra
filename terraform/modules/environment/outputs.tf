output "namespace_name" {
  description = "Nome do namespace criado"
  value       = kubernetes_namespace.devorbit.metadata[0].name
}

output "domain" {
  description = "Domínio completo do ambiente"
  value       = "${var.hash}.${var.domain_suffix}"
} 