#!/bin/bash

# Script para deployar bancos de dados no Kubernetes
# Uso: ./deploy-databases.sh [namespace]

set -e

NAMESPACE=${1:-default}
HASH=${2:-$(openssl rand -hex 3)}

echo "🚀 Deployando bancos de dados no namespace: $NAMESPACE"
echo "🔑 Hash do ambiente: $HASH"

# Criar namespace se não existir
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "📦 Criando namespace $NAMESPACE..."
    kubectl create namespace "$NAMESPACE"
fi

# Deploy MongoDB
echo "🍃 Deployando MongoDB..."
helm upgrade --install mongodb ./charts/mongodb \
    --namespace "$NAMESPACE" \
    --set hash="$HASH" \
    --set ttl="2"

# Aguardar MongoDB estar pronto
echo "⏳ Aguardando MongoDB estar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb -n "$NAMESPACE" --timeout=300s

# Deploy Redis
echo "🔴 Deployando Redis..."
helm upgrade --install redis ./charts/redis \
    --namespace "$NAMESPACE" \
    --set hash="$HASH" \
    --set ttl="2"

# Aguardar Redis estar pronto
echo "⏳ Aguardando Redis estar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n "$NAMESPACE" --timeout=300s

# Deploy Kafka (com Zookeeper)
echo "📨 Deployando Kafka..."
helm upgrade --install kafka ./charts/kafka \
    --namespace "$NAMESPACE" \
    --set hash="$HASH" \
    --set ttl="2"

# Aguardar Zookeeper estar pronto
echo "⏳ Aguardando Zookeeper estar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=zookeeper -n "$NAMESPACE" --timeout=300s

# Aguardar Kafka estar pronto
echo "⏳ Aguardando Kafka estar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n "$NAMESPACE" --timeout=300s

echo "✅ Todos os bancos de dados foram deployados com sucesso!"
echo ""
echo "📊 Status dos serviços:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name in (mongodb,redis,kafka)"
echo ""
echo "🔗 Conexões disponíveis:"
echo "  MongoDB: mongodb.$NAMESPACE.svc.cluster.local:27017"
echo "  Redis: redis.$NAMESPACE.svc.cluster.local:6379"
echo "  Kafka: kafka.$NAMESPACE.svc.cluster.local:9092"
echo ""
echo "🔑 Credenciais MongoDB:"
echo "  Database: devorbit"
echo "  Usuário: admin"
echo "  Senha: devorbit123"
echo "  Auth: desabilitado (desenvolvimento)" 