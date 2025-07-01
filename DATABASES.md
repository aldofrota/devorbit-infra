# 🗄️ Bancos de Dados - DevOrbit Infra

Este documento explica como usar os bancos de dados (PostgreSQL, Redis e Kafka) configurados com Helm Charts.

## 📋 Pré-requisitos

- Docker
- `kubectl` instalado
- `kind` instalado
- `helm` instalado

## 🚀 Primeiros Passos

### 1. Criar cluster local com kind

```bash
# Criar cluster
make kind-create

# Ou manualmente:
kind create cluster --name devorbit-staging --config kind/kind-config.yaml
```

### 2. Deployar bancos de dados

```bash
# Deployar em namespace padrão
./scripts/deploy-databases.sh

# Deployar em namespace específico
./scripts/deploy-databases.sh meu-ambiente

# Deployar com hash específico
./scripts/deploy-databases.sh meu-ambiente abc123
```

## 🧪 Testar Conexões

```bash
# Testar todos os bancos
./scripts/test-connections.sh

# Testar em namespace específico
./scripts/test-connections.sh meu-ambiente
```

## 📊 Estrutura dos Charts

### MongoDB (`charts/mongodb/`)

- **Imagem**: `mongo:7.0`
- **Porta**: 27017
- **Database**: `devorbit`
- **Usuário**: `admin`
- **Senha**: `devorbit123`
- **Auth**: desabilitado (desenvolvimento)

**Configurações principais**:

- Persistência desabilitada por padrão (usa `emptyDir`)
- Health checks com `mongosh`
- Recursos limitados para desenvolvimento

### Redis (`charts/redis/`)

- **Imagem**: `redis:7.0-alpine`
- **Porta**: 6379
- **Senha**: não configurada (desenvolvimento)
- **Max Memory**: 256MB

**Configurações principais**:

- Sem persistência (desenvolvimento)
- Health checks com `redis-cli ping`
- Política de evição: `allkeys-lru`

### Kafka (`charts/kafka/`)

- **Imagem**: `confluentinc/cp-kafka:7.4.0`
- **Porta**: 9092
- **Zookeeper**: incluído no mesmo chart
- **Replicação**: 1 (desenvolvimento)

**Configurações principais**:

- Zookeeper integrado
- Auto-criação de tópicos habilitada
- Health checks com `kafka-topics`

## 🔗 Conexões

### Dentro do Kubernetes

```bash
# MongoDB
mongodb://mongodb:27017/devorbit

# Redis
redis://redis:6379

# Kafka
kafka:9092
```

### De fora do cluster (port-forward)

```bash
# MongoDB
kubectl port-forward svc/mongodb 27017:27017 -n <namespace>

# Redis
kubectl port-forward svc/redis 6379:6379 -n <namespace>

# Kafka
kubectl port-forward svc/kafka 9092:9092 -n <namespace>
```

## 🛠️ Comandos Úteis

### Verificar status

```bash
# Ver pods
kubectl get pods -n <namespace> -l "app.kubernetes.io/name in (mongodb,redis,kafka)"

# Ver serviços
kubectl get svc -n <namespace> -l "app.kubernetes.io/name in (mongodb,redis,kafka)"

# Ver logs
kubectl logs deployment/mongodb -n <namespace>
kubectl logs deployment/redis -n <namespace>
kubectl logs deployment/kafka -n <namespace>
```

### Conectar diretamente

```bash
# MongoDB
kubectl exec -it deployment/mongodb -n <namespace> -- mongosh devorbit

# Redis
kubectl exec -it deployment/redis -n <namespace> -- redis-cli

# Kafka
kubectl exec -it deployment/kafka -n <namespace> -- kafka-topics --bootstrap-server localhost:9092 --list
```

### Limpar ambiente

```bash
# Remover namespace (remove tudo)
kubectl delete namespace <namespace>

# Ou usar o script de cleanup
./scripts/cleanup.sh
```

## 🔧 Customização

### MongoDB

```bash
helm upgrade mongodb ./charts/mongodb \
  --namespace <namespace> \
  --set mongodb.password=minha-senha \
  --set mongodb.database=meu-banco \
  --set persistence.enabled=true \
  --set persistence.size=20Gi
```

### Redis

```bash
helm upgrade redis ./charts/redis \
  --namespace <namespace> \
  --set redis.password=minha-senha \
  --set redis.maxmemory=512mb \
  --set persistence.enabled=true
```

### Kafka

```bash
helm upgrade kafka ./charts/kafka \
  --namespace <namespace> \
  --set kafka.logRetentionHours=24 \
  --set persistence.enabled=true
```

## 🚨 Troubleshooting

### MongoDB não inicia

```bash
# Ver logs
kubectl logs deployment/mongodb -n <namespace>

# Verificar se a porta está livre
kubectl get svc mongodb -n <namespace>
```

### Redis não responde

```bash
# Verificar se o pod está rodando
kubectl get pods -l app.kubernetes.io/name=redis -n <namespace>

# Testar conexão
kubectl exec deployment/redis -n <namespace> -- redis-cli ping
```

### Kafka não conecta

```bash
# Verificar se Zookeeper está pronto
kubectl get pods -l app.kubernetes.io/component=zookeeper -n <namespace>

# Verificar logs do Kafka
kubectl logs deployment/kafka -n <namespace>
```

## 📝 Próximos Passos

1. **Aprender Kubernetes básico**: `kubectl get`, `kubectl describe`, `kubectl logs`
2. **Entender Helm**: `helm list`, `helm get values`, `helm upgrade`
3. **Configurar Traefik**: para ingress e load balancing
4. **Implementar aplicações**: frontend, backend, SSO
5. **Automatizar com GitHub Actions**: deploy automático por PR
