variable "namespace_name" {
  description = "Nome do namespace"
  type        = string
}

variable "hash" {
  description = "Hash único do ambiente"
  type        = string
}

variable "ttl_hours" {
  description = "TTL em horas"
  type        = number
}

variable "domain_suffix" {
  description = "Sufixo do domínio"
  type        = string
  default     = "127.0.0.1.nip.io"
} 