#!/bin/bash

# Script para popular dados iniciais no ambiente DevOrbit
# Uso: ./seed.sh <namespace> <hash>

set -e

NAMESPACE=$1
HASH=$2

if [ -z "$NAMESPACE" ] || [ -z "$HASH" ]; then
    echo "Uso: $0 <namespace> <hash>"
    echo "Exemplo: $0 devorbit-abc123 abc123"
    exit 1
fi

echo "🌱 Populando dados iniciais para ambiente $HASH..."

# Criar Job para seed de dados
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: seed-data-${HASH}
  namespace: ${NAMESPACE}
  labels:
    devorbit/hash: ${HASH}
    devorbit/type: seed
spec:
  template:
    spec:
      containers:
      - name: seed
        image: mongo:7.0
        command:
        - /bin/bash
        - -c
        - |
          set -e
          echo "Aguardando MongoDB..."
          until mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
            sleep 2
          done
          
          echo "Criando dados iniciais..."
          mongosh devorbit << 'EOF'
          // Criar usuário de teste
          db.users.insertOne({
            email: 'user@devorbit.com',
            name: 'Usuário Teste',
            password_hash: '\$2b\$10\$dummy.hash.for.testing',
            created_at: new Date()
          });
          
          // Criar tribo de teste
          db.tribes.insertOne({
            name: 'Comunidade',
            description: 'Tribo de teste para desenvolvimento',
            created_at: new Date()
          });
          
          // Criar projeto de teste
          db.projects.insertOne({
            name: 'Projeto Teste',
            description: 'Projeto para testes de PR',
            tribe_name: 'Comunidade',
            created_at: new Date()
          });
          
          print("Dados iniciais criados com sucesso!");
          EOF
      restartPolicy: OnFailure
      backoffLimit: 3
EOF

echo "✅ Job de seed criado. Aguardando conclusão..."

# Aguardar conclusão do job
kubectl wait --for=condition=complete job/seed-data-${HASH} -n ${NAMESPACE} --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ Dados iniciais populados com sucesso!"
    echo "📧 Usuário: user@devorbit.com"
    echo "🔑 Senha: dev123"
else
    echo "❌ Erro ao popular dados iniciais"
    kubectl logs job/seed-data-${HASH} -n ${NAMESPACE}
    exit 1
fi 