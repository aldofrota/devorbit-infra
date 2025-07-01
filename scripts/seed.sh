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
        image: postgres:15
        command:
        - /bin/bash
        - -c
        - |
          set -e
          echo "Aguardando PostgreSQL..."
          until pg_isready -h postgres -p 5432 -U postgres; do
            sleep 2
          done
          
          echo "Criando dados iniciais..."
          psql -h postgres -U postgres -d devorbit << 'EOF'
          -- Criar usuário de teste
          INSERT INTO users (email, name, password_hash, created_at) 
          VALUES ('user@devorbit.com', 'Usuário Teste', '\$2b\$10\$dummy.hash.for.testing', NOW())
          ON CONFLICT (email) DO NOTHING;
          
          -- Criar tribo de teste
          INSERT INTO tribes (name, description, created_at)
          VALUES ('Comunidade', 'Tribo de teste para desenvolvimento', NOW())
          ON CONFLICT (name) DO NOTHING;
          
          -- Criar projeto de teste
          INSERT INTO projects (name, description, tribe_id, created_at)
          SELECT 'Projeto Teste', 'Projeto para testes de PR', t.id, NOW()
          FROM tribes t WHERE t.name = 'Comunidade'
          ON CONFLICT (name) DO NOTHING;
          
          echo "Dados iniciais criados com sucesso!"
          EOF
        env:
        - name: PGPASSWORD
          value: "devorbit123"
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