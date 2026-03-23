#!/bin/bash
# ==============================================================================
# SCRIPT: bootstrap_backend.sh (IDEMPOTENTE)
# ==============================================================================
set -e

PROJECT="finnow-drx"
REGION="us-east-1"
TABLE_NAME="${PROJECT}-terraform-locks"

# Buscamos si ya existe un bucket con nuestro prefijo para reutilizarlo
EXISTING_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${PROJECT}-terraform-state-')].Name" --output text)

if [ -z "$EXISTING_BUCKET" ]; then
    BUCKET_NAME="${PROJECT}-terraform-state-$(date +%s)"
    echo "📦 Creando nuevo Bucket S3: $BUCKET_NAME..."
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
    aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    echo "✅ Bucket creado y protegido."
else
    BUCKET_NAME=$EXISTING_BUCKET
    echo "ℹ️ Reutilizando Bucket existente: $BUCKET_NAME"
fi

# Chequeo Idempotente de DynamoDB
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "🔒 Creando Tabla DynamoDB: $TABLE_NAME..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
    echo "✅ Tabla de bloqueo creada."
else
    echo "ℹ️ La tabla $TABLE_NAME ya existe. Saltando..."
fi

# ... (después de crear la tabla DynamoDB)

# 3. Generar archivo de configuración para Terragrunt automáticamente
CONFIG_FILE="terragrunt/backend_config.hcl"

echo "⚙️ Generando configuración automática en $CONFIG_FILE..."

cat <<EOF > "$CONFIG_FILE"
# ARCHIVO GENERADO AUTOMÁTICAMENTE - NO EDITAR MANUALMENTE
locals {
  remote_state_bucket = "$BUCKET_NAME"
  remote_state_region = "$REGION"
  dynamodb_table      = "$TABLE_NAME"
}
EOF

echo "✅ Configuración de backend inyectada con éxito."

echo "-------------------------------------------------------"
echo "RESUMEN PARA TERRAGRUNT:"
echo "BUCKET_NAME=$BUCKET_NAME"
echo "-------------------------------------------------------"
