#!/bin/bash
# ==============================================================================
# SCRIPT: cleanup_backend.sh (DESTRUCCIÓN CONTROLADA)
# ==============================================================================
PROJECT="finnow-drx"
REGION="us-east-1"
TABLE_NAME="${PROJECT}-terraform-locks"

# 1. Identificar el bucket
BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${PROJECT}-terraform-state-')].Name" --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No se encontró ningún bucket de backend para eliminar."
    exit 0
fi

echo "⚠️ ADVERTENCIA: Se eliminará el bucket $BUCKET_NAME y la tabla $TABLE_NAME."
echo "Esto borrará permanentemente el historial de toda la infraestructura."
read -p "Confirmar eliminación (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "❌ Operación cancelada."
    exit 0
fi

echo "🧹 Vaciando todas las versiones del bucket (esto puede tardar)..."
# Eliminar versiones de objetos
aws s3api delete-objects --bucket "$BUCKET_NAME" \
    --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

# Eliminar marcadores de borrado
aws s3api delete-objects --bucket "$BUCKET_NAME" \
    --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

echo "🗑️ Eliminando Bucket S3..."
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"

echo "🗑️ Eliminando Tabla DynamoDB..."
aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION"

echo "✅ Limpieza completada exitosamente."
