# 🚀 Setup do Ambiente DevOrbit

Este documento explica como configurar e usar o ambiente de staging dinâmico DevOrbit.

## 📋 Pré-requisitos

### Ferramentas Necessárias

1. **Docker** - Para containers

   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER
   ```

2. **kind** - Kubernetes local

   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

3. **kubectl** - Cliente Kubernetes

   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```

4. **Helm** - Gerenciador de pacotes Kubernetes

   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

5. **Terraform** - Infraestrutura como código

   ```bash
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install terraform
   ```

6. **Node.js** - Para o bot Slack
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

### Contas e Tokens

1. **DockerHub** - Para push de imagens

   - Criar conta em https://hub.docker.com
   - Criar repositórios públicos: `devorbit/frontend`, `devorbit/backend`, `devorbit/sso`

2. **Slack** - Para o bot
   - Criar app em https://api.slack.com/apps
   - Configurar comandos: `/deploy`, `/status`, `/cleanup`
   - Obter tokens: `SLACK_BOT_TOKEN`, `SLACK_SIGNING_SECRET`, `SLACK_APP_TOKEN`

## 🔧 Configuração Inicial

### 1. Clone e Setup

```bash
git clone <seu-repo>
cd devorbit-infra

# Verificar dependências
make setup
```

### 2. Configurar Secrets

Criar arquivo `.env` no diretório `slack-bot/`:

```bash
SLACK_BOT_TOKEN=xoxb-seu-token
SLACK_SIGNING_SECRET=seu-signing-secret
SLACK_APP_TOKEN=xapp-seu-app-token
```

### 3. Configurar GitHub Secrets

No seu repositório GitHub, adicionar secrets:

- `DOCKERHUB_USERNAME` - Seu usuário DockerHub
- `DOCKERHUB_TOKEN` - Token de acesso DockerHub

## 🚀 Primeiro Deploy

### Opção 1: Deploy Completo (Recomendado)

```bash
# Deploy completo com hash aleatório
make deploy-full

# Ou com hash específico
HASH=abc123 make deploy-full
```

### Opção 2: Deploy Manual

```bash
# 1. Criar cluster
make kind-create

# 2. Inicializar Terraform
make terraform-init

# 3. Aplicar infraestrutura
HASH=abc123 make terraform-apply

# 4. Deploy aplicações
HASH=abc123 make helm-deploy
```

## 🤖 Configurando o Bot Slack

### 1. Instalar Dependências

```bash
make slack-bot-install
```

### 2. Configurar App Slack

1. Acesse https://api.slack.com/apps
2. Crie um novo app
3. Em "OAuth & Permissions":
   - Adicione scopes: `commands`, `chat:write`
   - Instale o app no workspace
4. Em "Slash Commands":
   - Crie comando `/deploy`
   - Crie comando `/status`
   - Crie comando `/cleanup`
5. Em "Basic Information":
   - Copie "Signing Secret"
   - Em "App-Level Tokens", crie um token com scope `connections:write`

### 3. Iniciar Bot

```bash
make slack-bot-start
```

## 📝 Uso

### Comandos Slack

```
/deploy frontend=pr42 backend=pr18 sso=main ttl=4
```

Parâmetros:

- `frontend` - Imagem do frontend (ex: `pr42`, `main`)
- `backend` - Imagem do backend (ex: `pr18`, `main`)
- `sso` - Imagem do SSO (ex: `main`, `pr5`)
- `ttl` - Tempo de vida em horas (padrão: 2)

### Comandos Make

```bash
# Ver todos os comandos
make help

# Setup de desenvolvimento
make dev-setup

# Limpeza
make cleanup

# Limpeza completa
make dev-cleanup
```

## 🔍 Monitoramento

### Verificar Status

```bash
# Ambientes ativos
kubectl get namespaces -l devorbit/hash

# Pods de um ambiente
kubectl get pods -n devorbit-abc123

# Logs de um serviço
kubectl logs -n devorbit-abc123 deployment/frontend
```

### Acessar Aplicação

Após o deploy, acesse:

- **URL**: `https://abc123.127.0.0.1.nip.io`
- **Usuário**: `user@devorbit.com`
- **Senha**: `dev123`

## 🧹 Limpeza Automática

O sistema possui limpeza automática configurada para:

1. **GitHub Actions** - Executa a cada hora
2. **Bot Slack** - Cron job interno
3. **Manual** - Comando `/cleanup` no Slack

### Verificar Limpeza

```bash
# Modo dry-run
./scripts/cleanup.sh --dry-run

# Executar limpeza
./scripts/cleanup.sh
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **Cluster kind não inicia**

   ```bash
   # Verificar Docker
   docker ps

   # Recriar cluster
   make kind-delete
   make kind-create
   ```

2. **Terraform falha**

   ```bash
   # Limpar estado
   cd terraform && rm -rf .terraform terraform.tfstate*
   make terraform-init
   ```

3. **Helm falha**

   ```bash
   # Verificar repositórios
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo add traefik https://traefik.github.io/charts
   helm repo update
   ```

4. **Bot Slack não responde**

   ```bash
   # Verificar tokens
   cat slack-bot/.env

   # Verificar logs
   cd slack-bot && npm start
   ```

### Logs Úteis

```bash
# Logs do cluster
kubectl get events --all-namespaces

# Logs do Traefik
kubectl logs -n devorbit-abc123 deployment/traefik

# Logs do PostgreSQL
kubectl logs -n devorbit-abc123 deployment/postgres
```

## 📚 Próximos Passos

1. **Configurar CI/CD** - Integrar com repositórios dos serviços
2. **Monitoramento** - Adicionar Prometheus/Grafana
3. **Backup** - Configurar backup automático do banco
4. **Segurança** - Implementar autenticação mais robusta
5. **Escalabilidade** - Configurar HPA (Horizontal Pod Autoscaler)
