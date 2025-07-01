#!/bin/bash

# Exemplo de como conectar uma aplicação aos bancos de dados
# Este script mostra como testar as conexões de uma aplicação

set -e

NAMESPACE=${1:-default}

echo "🔗 Exemplo de conexão com bancos de dados"
echo "Namespace: $NAMESPACE"
echo ""

# Verificar se os bancos estão rodando
echo "📊 Verificando status dos bancos..."
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name in (mongodb,redis,kafka)" --no-headers | while read -r line; do
    pod_name=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $3}')
    echo "  $pod_name: $status"
done
echo ""

# Exemplo de variáveis de ambiente para aplicação
echo "🌍 Variáveis de ambiente para sua aplicação:"
echo ""
echo "# MongoDB"
echo "MONGODB_URL=mongodb://mongodb.$NAMESPACE.svc.cluster.local:27017/devorbit"
echo ""
echo "# Redis"
echo "REDIS_URL=redis://redis.$NAMESPACE.svc.cluster.local:6379"
echo ""
echo "# Kafka"
echo "KAFKA_BROKERS=kafka.$NAMESPACE.svc.cluster.local:9092"
echo ""

# Exemplo de conexão Node.js
echo "📝 Exemplo de código Node.js:"
echo ""
echo "// MongoDB (usando mongodb)"
echo "const { MongoClient } = require('mongodb');"
echo "const client = new MongoClient('mongodb://mongodb.$NAMESPACE.svc.cluster.local:27017');"
echo "const db = client.db('devorbit');"
echo ""

echo "// Redis (usando redis)"
echo "const redis = require('redis');"
echo "const client = redis.createClient({"
echo "  url: 'redis://redis.$NAMESPACE.svc.cluster.local:6379'"
echo "});"
echo ""

echo "// Kafka (usando kafkajs)"
echo "const { Kafka } = require('kafkajs');"
echo "const kafka = new Kafka({"
echo "  clientId: 'my-app',"
echo "  brokers: ['kafka.$NAMESPACE.svc.cluster.local:9092']"
echo "});"
echo ""

# Exemplo de conexão Python
echo "🐍 Exemplo de código Python:"
echo ""
echo "# MongoDB (usando pymongo)"
echo "from pymongo import MongoClient"
echo "client = MongoClient('mongodb://mongodb.$NAMESPACE.svc.cluster.local:27017')"
echo "db = client['devorbit']"
echo ""

echo "# Redis (usando redis)"
echo "import redis"
echo "r = redis.Redis("
echo "    host='redis.$NAMESPACE.svc.cluster.local',"
echo "    port=6379"
echo ")"
echo ""

echo "# Kafka (usando kafka-python)"
echo "from kafka import KafkaProducer, KafkaConsumer"
echo "producer = KafkaProducer("
echo "    bootstrap_servers=['kafka.$NAMESPACE.svc.cluster.local:9092']"
echo ")"
echo ""

# Testar conexões
echo "🧪 Testando conexões..."
echo ""

# MongoDB
echo "🍃 Testando MongoDB..."
if kubectl exec -n "$NAMESPACE" deployment/mongodb -- mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    echo "✅ MongoDB: OK"
else
    echo "❌ MongoDB: FALHOU"
fi

# Redis
echo "🔴 Testando Redis..."
if kubectl exec -n "$NAMESPACE" deployment/redis -- redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis: OK"
else
    echo "❌ Redis: FALHOU"
fi

# Kafka
echo "📨 Testando Kafka..."
if kubectl exec -n "$NAMESPACE" deployment/kafka -- kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
    echo "✅ Kafka: OK"
else
    echo "❌ Kafka: FALHOU"
fi

echo ""
echo "🎉 Exemplo concluído!"
echo ""
echo "💡 Dica: Use 'kubectl port-forward' para conectar de fora do cluster:"
echo "  kubectl port-forward svc/mongodb 27017:27017 -n $NAMESPACE"
echo "  kubectl port-forward svc/redis 6379:6379 -n $NAMESPACE"
echo "  kubectl port-forward svc/kafka 9092:9092 -n $NAMESPACE" 