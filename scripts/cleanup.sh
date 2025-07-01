#!/bin/bash

# Script para limpeza automática de ambientes DevOrbit expirados
# Uso: ./cleanup.sh [--dry-run]

set -e

DRY_RUN=false

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "🔍 Modo dry-run ativado"
fi

echo "🧹 Iniciando limpeza de ambientes expirados..."

# Função para calcular tempo decorrido em horas
get_hours_elapsed() {
    local created_at=$1
    local now=$(date +%s)
    local created=$(date -d "$created_at" +%s 2>/dev/null || echo "0")
    echo $(( (now - created) / 3600 ))
}

# Buscar namespaces com label devorbit/hash
NAMESPACES=$(kubectl get namespaces -l devorbit/hash -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.devorbit/ttl}{"\t"}{.metadata.labels.devorbit/created-at}{"\n"}{end}')

if [ -z "$NAMESPACES" ]; then
    echo "✅ Nenhum ambiente DevOrbit encontrado"
    exit 0
fi

echo "$NAMESPACES" | while IFS=$'\t' read -r namespace ttl created_at; do
    if [ -z "$namespace" ]; then
        continue
    fi
    
    # Extrair hash do nome do namespace
    hash=$(echo "$namespace" | sed 's/devorbit-//')
    
    # Calcular horas decorridas
    hours_elapsed=$(get_hours_elapsed "$created_at")
    
    echo "📊 Ambiente: $namespace (hash: $hash)"
    echo "   ⏰ Criado há: ${hours_elapsed}h"
    echo "   ⏳ TTL: ${ttl}h"
    
    # Verificar se expirou
    if [ "$hours_elapsed" -ge "$ttl" ]; then
        echo "   ❌ EXPIRADO - Removendo..."
        
        if [ "$DRY_RUN" = false ]; then
            # Remover namespace (isso remove todos os recursos)
            kubectl delete namespace "$namespace" --wait=true --timeout=300s
            
            if [ $? -eq 0 ]; then
                echo "   ✅ Ambiente $namespace removido com sucesso"
            else
                echo "   ⚠️  Erro ao remover ambiente $namespace"
            fi
        else
            echo "   🔍 [DRY-RUN] Seria removido: $namespace"
        fi
    else
        echo "   ✅ Válido - Mantendo"
    fi
    echo ""
done

echo "✅ Limpeza concluída!" 