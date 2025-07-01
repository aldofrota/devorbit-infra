#!/bin/bash

# Script para testar conexões com os bancos de dados
# Uso: ./test-connections.sh [namespace]

set -e

NAMESPACE=${1:-default}

echo "🧪 Testando conexões com os bancos de dados no namespace: $NAMESPACE"
echo ""

# Testar MongoDB
echo "🍃 Testando MongoDB..."
if kubectl exec -n "$NAMESPACE" deployment/mongodb -- mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    echo "✅ MongoDB está funcionando!"
    
    # Testar query simples
    echo "📊 Executando query de teste..."
    kubectl exec -n "$NAMESPACE" deployment/mongodb -- mongosh --eval "db.version()" 2>/dev/null | head -2
else
    echo "❌ MongoDB não está respondendo"
fi
echo ""

# Testar Redis
echo "🔴 Testando Redis..."
if kubectl exec -n "$NAMESPACE" deployment/redis -- redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis está funcionando!"
    
    # Testar operação simples
    echo "📊 Testando operação SET/GET..."
    kubectl exec -n "$NAMESPACE" deployment/redis -- redis-cli set test "hello" >/dev/null 2>&1
    kubectl exec -n "$NAMESPACE" deployment/redis -- redis-cli get test 2>/dev/null
else
    echo "❌ Redis não está respondendo"
fi
echo ""

# Testar Kafka
echo "📨 Testando Kafka..."
if kubectl exec -n "$NAMESPACE" deployment/kafka -- kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
    echo "✅ Kafka está funcionando!"
    
    # Listar tópicos
    echo "📊 Listando tópicos existentes..."
    kubectl exec -n "$NAMESPACE" deployment/kafka -- kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null || echo "Nenhum tópico encontrado"
else
    echo "❌ Kafka não está respondendo"
fi
echo ""

# Mostrar status dos pods
echo "📊 Status dos pods:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name in (mongodb,redis,kafka)" -o wide
echo ""

# Mostrar serviços
echo "🔗 Serviços disponíveis:"
kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/name in (mongodb,redis,kafka)" 