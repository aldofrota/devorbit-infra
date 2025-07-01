## 🛠️ DevOrbit - Setup de Ambiente de Staging Dinâmico com Kubernetes, Helm, Traefik, Terraform e Slack (100% Local com kind)

### ✅ Objetivo Final

Criar uma infraestrutura local para testes de Pull Requests da plataforma DevOrbit com:

- Subdomínio único por PR (ex: `abc123.127.0.0.1.nip.io`)
- Todos os serviços (frontend, backend, sso) no mesmo namespace (ex: `devorbit-abc123`)
- Cada serviço com imagem específica (ex: frontend PR #42, sso PR #18)
- Comunicação entre os serviços via DNS interno (ex: `http://backend:3000`)
- Banco, Redis, Kafka para apoio
- Seed de dados automatizado
- Criação via bot Slack com feedback em tempo real
- Limpeza automática após X horas

---

### 📦 Requisitos

- Docker
- Conta no DockerHub (para push de imagens públicas)
- Node.js (para bot Slack)
- `kubectl`
- [`kind`](https://kind.sigs.k8s.io/) (Kubernetes local)
- `helm`
- `terraform`
- `jq` e `yq` (CLI para manipulação de JSON/YAML)

---

### 📁 Estrutura do repositório principal

```bash
devorbit-infra/
├── README.md                     # Visão geral e como rodar
├── .github/
│   └── workflows/               # Actions para deploy, build e cleanup
├── charts/                      # Helm charts dos serviços
│   ├── frontend/
│   ├── backend/
│   ├── sso/
│   ├── mongodb/
│   ├── redis/
│   └── kafka/
├── terraform/                   # Código para provisionamento local
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
├── kind/
│   └── kind-config.yaml         # Config do cluster local
├── scripts/                     # Scripts auxiliares
│   ├── seed.sh
│   └── cleanup.sh
├── slack-bot/                   # Bot Slack interativo
│   └── index.js
└── values/
    └── abc123.yaml              # Valores dinâmicos por PR (opcional)
```

---

### 🐳 Push de imagens para DockerHub

Se os repositórios forem públicos, você pode usar o DockerHub:

**Requisitos:**

- Criar repositório público no DockerHub: `devorbit/frontend`, `devorbit/backend`, etc.
- Configurar `secrets.DOCKERHUB_USERNAME` e `secrets.DOCKERHUB_TOKEN` no GitHub

**Exemplo de GitHub Action (frontend/.github/workflows/pr.yml):**

```yaml
name: Build PR Image

on:
  pull_request:
    paths:
      - "**"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build & Push to DockerHub
        run: |
          docker build -t devorbit/frontend:pr-${{ github.event.pull_request.number }} .
          echo ${{ secrets.DOCKERHUB_TOKEN }} | docker login -u ${{ secrets.DOCKERHUB_USERNAME }} --password-stdin
          docker push devorbit/frontend:pr-${{ github.event.pull_request.number }}
```

**No Helm:**

```yaml
image:
  repository: devorbit/frontend
  tag: pr-42
```

---

### 🔁 Deploy de múltiplas imagens no mesmo namespace

Ao criar o ambiente local:

```bash
export HASH=abc123
kubectl create namespace devorbit-$HASH

helm upgrade --install frontend ./charts/frontend \
  --namespace devorbit-$HASH \
  --set image.repository=devorbit/frontend \
  --set image.tag=pr-42 \
  --set ingress.host=$HASH.127.0.0.1.nip.io \
  --set env[0].name=VITE_API_URL \
  --set env[0].value=http://backend:3000

helm upgrade --install backend ./charts/backend \
  --namespace devorbit-$HASH \
  --set image.tag=main

helm upgrade --install sso ./charts/sso \
  --namespace devorbit-$HASH \
  --set image.tag=pr-18
```

Todos os serviços se comunicam via DNS interno do Kubernetes (`backend`, `sso`, etc).

---

### 🧪 Seed, TTL e Slack Bot

- Script `seed.sh` roda Job de inicialização com dados fake
- TTL é marcado por label: `devorbit/ttl: "2h"`
- CronJob local remove namespaces expirados
- Bot Slack envia instruções, executa Terraform e Helm, responde com o domínio e acesso

---

### ✅ Exemplo de comando Slack

```
/deploy tribo=comunidade frontend=pr42 sso=pr18 backend=main
```

⬇️

```
✅ Ambiente criado!
https://abc123.127.0.0.1.nip.io
Usuário: user@devorbit.com
Senha: dev123
Expira em: 2h
```

---

Se quiser, posso te gerar o repositório base com essa estrutura já inicializada. Deseja isso?
