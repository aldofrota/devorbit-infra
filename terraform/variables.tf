variable "namespace_name" {
  description = "Nome do namespace para o ambiente DevOrbit"
  type        = string
  default     = "devorbit-staging"
}

variable "hash" {
  description = "Hash único para identificar o ambiente (ex: abc123)"
  type        = string
}

variable "ttl_hours" {
  description = "Tempo de vida do ambiente em horas"
  type        = number
  default     = 2
}

variable "frontend_image" {
  description = "Imagem do frontend (ex: devorbit/frontend:pr-42)"
  type        = string
  default     = "devorbit/frontend:latest"
}

variable "backend_image" {
  description = "Imagem do backend (ex: devorbit/backend:pr-18)"
  type        = string
  default     = "devorbit/backend:latest"
}

variable "sso_image" {
  description = "Imagem do SSO (ex: devorbit/sso:main)"
  type        = string
  default     = "devorbit/sso:latest"
}

variable "domain_suffix" {
  description = "Sufixo do domínio para nip.io"
  type        = string
  default     = "127.0.0.1.nip.io"
} 