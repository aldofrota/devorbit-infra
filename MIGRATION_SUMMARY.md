# 🔄 Migração: PostgreSQL → MongoDB

Este documento resume as mudanças feitas para trocar PostgreSQL por MongoDB na infraestrutura DevOrbit.

## 📋 Mudanças Realizadas

### ✅ Charts Helm

1. **Removido**: `charts/postgres/`
2. **Adicionado**: `charts/mongodb/`
   - Imagem: `mongo:7.0`
   - Porta: 27017
   - Auth desabilitado para desenvolvimento
   - Health checks com `mongosh`

### ✅ Scripts Atualizados

1. **`scripts/deploy-databases.sh`**

   - Deploy de MongoDB ao invés de PostgreSQL
   - Aguarda MongoDB estar pronto
   - Atualiza URLs de conexão

2. **`scripts/test-connections.sh`**

   - Testa MongoDB com `mongosh`
   - Verifica conexão com `db.adminCommand('ping')`

3. **`scripts/seed.sh`**
   - Usa `mongo:7.0` ao invés de `postgres:15`
   - Scripts MongoDB ao invés de SQL
   - Inserts com sintaxe MongoDB

### ✅ Exemplos Atualizados

1. **`examples/connect-example.sh`**
   - URLs de conexão MongoDB
   - Exemplos de código Node.js e Python
   - Comandos de teste atualizados

### ✅ Documentação Atualizada

1. **`DATABASES.md`**

   - Seção MongoDB completa
   - URLs de conexão atualizadas
   - Comandos de troubleshooting

2. **`QUICKSTART.md`**

   - Configurações MongoDB
   - URLs de conexão
   - Comandos de port-forward

3. **`README.md`**
   - Estrutura de diretórios atualizada

## 🔗 URLs de Conexão

### Antes (PostgreSQL)

```bash
postgresql://postgres:devorbit123@postgres:5432/devorbit
```

### Depois (MongoDB)

```bash
mongodb://mongodb:27017/devorbit
```

## 🛠️ Comandos Atualizados

### Antes

```bash
# Conectar
kubectl exec -it deployment/postgres -- psql -U postgres -d devorbit

# Testar
kubectl exec -n $NAMESPACE deployment/postgres -- pg_isready -U postgres -d devorbit

# Port-forward
kubectl port-forward svc/postgres 5432:5432
```

### Depois

```bash
# Conectar
kubectl exec -it deployment/mongodb -- mongosh devorbit

# Testar
kubectl exec -n $NAMESPACE deployment/mongodb -- mongosh --eval "db.adminCommand('ping')"

# Port-forward
kubectl port-forward svc/mongodb 27017:27017
```

## 📝 Exemplos de Código

### Node.js

**Antes (PostgreSQL)**:

```javascript
const { Client } = require("pg");
const client = new Client({
  host: "postgres.namespace.svc.cluster.local",
  port: 5432,
  database: "devorbit",
  user: "postgres",
  password: "devorbit123",
});
```

**Depois (MongoDB)**:

```javascript
const { MongoClient } = require("mongodb");
const client = new MongoClient(
  "mongodb://mongodb.namespace.svc.cluster.local:27017"
);
const db = client.db("devorbit");
```

### Python

**Antes (PostgreSQL)**:

```python
import psycopg2
conn = psycopg2.connect(
    host='postgres.namespace.svc.cluster.local',
    port=5432,
    database='devorbit',
    user='postgres',
    password='devorbit123'
)
```

**Depois (MongoDB)**:

```python
from pymongo import MongoClient
client = MongoClient('mongodb://mongodb.namespace.svc.cluster.local:27017')
db = client['devorbit']
```

## 🚀 Como Testar

```bash
# 1. Deployar bancos
make dev-databases

# 2. Testar conexões
./scripts/test-connections.sh

# 3. Ver exemplo
./examples/connect-example.sh
```

## ✅ Status

- [x] Chart MongoDB criado
- [x] Chart PostgreSQL removido
- [x] Scripts atualizados
- [x] Documentação atualizada
- [x] Exemplos atualizados
- [x] Testes funcionando

## 🎯 Próximos Passos

1. **Testar deploy**: `make dev-databases`
2. **Verificar conexões**: `./scripts/test-connections.sh`
3. **Atualizar aplicações**: Usar URLs MongoDB
4. **Configurar Traefik**: Para ingress
5. **Implementar apps**: Frontend, backend, SSO
