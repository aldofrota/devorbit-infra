# 🚀 Quick Start - DevOrbit Infra

Guia rápido para começar com os bancos de dados no Kubernetes.

## ⚡ Comandos Rápidos

### 1. Setup inicial (uma vez só)

```bash
# Verificar dependências
make setup

# Criar cluster local
make kind-create
```

### 2. Deployar bancos de dados

```bash
# Deploy completo com testes
make dev-databases

# Ou manualmente:
./scripts/deploy-databases.sh
./scripts/test-connections.sh
```

### 3. Testar conexões

```bash
# Ver status
kubectl get pods -l "app.kubernetes.io/name in (postgres,redis,kafka)"

# Testar conexões
./scripts/test-connections.sh

# Ver exemplo de código
./examples/connect-example.sh
```

### 4. Limpar ambiente

```bash
# Limpar tudo
make dev-cleanup

# Ou apenas bancos
kubectl delete namespace default
```

## 📊 O que foi configurado

### ✅ MongoDB

- **Porta**: 27017
- **Database**: `devorbit`
- **Usuário**: `admin`
- **Senha**: `devorbit123`
- **URL**: `mongodb://mongodb:27017/devorbit`

### ✅ Redis

- **Porta**: 6379
- **Senha**: nenhuma (desenvolvimento)
- **URL**: `redis://redis:6379`

### ✅ Kafka

- **Porta**: 9092
- **Zookeeper**: incluído
- **URL**: `kafka:9092`

## 🔗 Conexões para aplicações

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
kubectl port-forward svc/mongodb 27017:27017

# Redis
kubectl port-forward svc/redis 6379:6379

# Kafka
kubectl port-forward svc/kafka 9092:9092
```

## 🛠️ Comandos úteis

```bash
# Ver todos os comandos disponíveis
make help

# Ver logs de um serviço
kubectl logs deployment/postgres
kubectl logs deployment/redis
kubectl logs deployment/kafka

# Conectar diretamente
kubectl exec -it deployment/mongodb -- mongosh devorbit
kubectl exec -it deployment/redis -- redis-cli
kubectl exec -it deployment/kafka -- kafka-topics --bootstrap-server localhost:9092 --list
```

## 📝 Próximos passos

1. **Aprender Kubernetes básico**: `kubectl get`, `kubectl describe`, `kubectl logs`
2. **Entender Helm**: `helm list`, `helm get values`, `helm upgrade`
3. **Configurar Traefik**: para ingress e load balancing
4. **Implementar aplicações**: frontend, backend, SSO
5. **Automatizar com GitHub Actions**: deploy automático por PR

## 🚨 Troubleshooting

### Banco não inicia

```bash
# Ver logs
kubectl logs deployment/<nome-do-banco>

# Verificar se o pod está rodando
kubectl get pods -l app.kubernetes.io/name=<nome-do-banco>

# Descrever pod para mais detalhes
kubectl describe pod -l app.kubernetes.io/name=<nome-do-banco>
```

### Cluster não funciona

```bash
# Verificar se kind está rodando
kind get clusters

# Recriar cluster
make kind-delete
make kind-create
```

## 📚 Documentação completa

- [DATABASES.md](DATABASES.md) - Documentação detalhada dos bancos
- [README.md](README.md) - Visão geral do projeto
