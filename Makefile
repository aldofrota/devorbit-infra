.PHONY: help setup kind-create kind-delete terraform-init terraform-apply terraform-destroy helm-deploy slack-bot-install slack-bot-start cleanup

# Variáveis
HASH ?= $(shell openssl rand -hex 3)
NAMESPACE = devorbit-$(HASH)
DOMAIN = $(HASH).127.0.0.1.nip.io

help: ## Mostra esta ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Configura o ambiente inicial
	@echo "🚀 Configurando ambiente DevOrbit..."
	@echo "📦 Instalando dependências..."
	@which kind || (echo "❌ kind não encontrado. Instale em: https://kind.sigs.k8s.io/" && exit 1)
	@which kubectl || (echo "❌ kubectl não encontrado. Instale em: https://kubernetes.io/docs/tasks/tools/" && exit 1)
	@which helm || (echo "❌ helm não encontrado. Instale em: https://helm.sh/docs/intro/install/" && exit 1)
	@which terraform || (echo "❌ terraform não encontrado. Instale em: https://www.terraform.io/downloads" && exit 1)
	@echo "✅ Dependências verificadas!"

kind-create: ## Cria cluster kind local
	@echo "🐳 Criando cluster kind..."
	kind create cluster --name devorbit-staging --config kind/kind-config.yaml
	@echo "✅ Cluster kind criado!"

kind-delete: ## Remove cluster kind local
	@echo "🗑️ Removendo cluster kind..."
	kind delete cluster --name devorbit-staging
	@echo "✅ Cluster kind removido!"

terraform-init: ## Inicializa Terraform
	@echo "🔧 Inicializando Terraform..."
	cd terraform && terraform init
	@echo "✅ Terraform inicializado!"

terraform-apply: ## Aplica configuração Terraform
	@echo "🚀 Aplicando configuração Terraform..."
	cd terraform && terraform apply -auto-approve -var="hash=$(HASH)" -var="ttl_hours=2"
	@echo "✅ Terraform aplicado!"

terraform-destroy: ## Destrói recursos Terraform
	@echo "🗑️ Destruindo recursos Terraform..."
	cd terraform && terraform destroy -auto-approve
	@echo "✅ Recursos Terraform destruídos!"

helm-deploy: ## Deploy com Helm
	@echo "⚓ Fazendo deploy com Helm..."
	helm upgrade --install frontend ./charts/frontend --namespace $(NAMESPACE) --set ingress.hosts[0].host=$(DOMAIN)
	helm upgrade --install backend ./charts/backend --namespace $(NAMESPACE)
	helm upgrade --install sso ./charts/sso --namespace $(NAMESPACE)
	@echo "✅ Deploy Helm concluído!"

slack-bot-install: ## Instala dependências do bot Slack
	@echo "🤖 Instalando dependências do bot Slack..."
	cd slack-bot && npm install
	@echo "✅ Dependências instaladas!"

slack-bot-start: ## Inicia o bot Slack
	@echo "🤖 Iniciando bot Slack..."
	cd slack-bot && npm start

cleanup: ## Executa limpeza de ambientes expirados
	@echo "🧹 Executando limpeza..."
	./scripts/cleanup.sh
	@echo "✅ Limpeza concluída!"

deploy-full: setup kind-create terraform-init terraform-apply helm-deploy ## Deploy completo do ambiente
	@echo "🎉 Deploy completo concluído!"
	@echo "🌐 URL: https://$(DOMAIN)"
	@echo "📧 Usuário: user@devorbit.com"
	@echo "🔑 Senha: dev123"

# Comandos de desenvolvimento
dev-setup: setup kind-create terraform-init ## Setup para desenvolvimento
	@echo "✅ Ambiente de desenvolvimento configurado!"

dev-cleanup: cleanup kind-delete ## Limpeza completa para desenvolvimento
	@echo "✅ Ambiente de desenvolvimento limpo!" 