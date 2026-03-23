#!/bin/bash
# ==============================================================================
# SCRIPT: monitor_aws.sh (EVOLUCIONADO)
# DESCRIPCIÓN: Auditoría forense de Backend y Red Multi-Región.
# ==============================================================================

echo "-------------------------------------------------------"
echo "🔐 ESTADO DEL BACKEND (Gobernanza)"
echo "-------------------------------------------------------"
echo "📦 S3 Buckets de Estado:"
aws s3 ls | grep finnow
echo -e "\n🔒 Tablas de Bloqueo DynamoDB:"
aws dynamodb list-tables --query "TableNames[?contains(@, 'finnow')]" --output table

echo -e "\n-------------------------------------------------------"
echo "🌐 INFRAESTRUCTURA DE RED (Networking)"
echo "-------------------------------------------------------"
echo "🗺️ VPCs en us-east-1 (Virginia) y us-west-2 (Oregon):"
# Este comando busca en las regiones principales de nuestro proyecto
for region in us-east-1 us-west-2; do
    echo "📍 Región: $region"
    aws ec2 describe-vpcs --region $region --filters "Name=tag:Project,Values=finnow-drx" \
        --query "Vpcs[*].{Name:Tags[?Key=='Name']|[0].Value, CIDR:CidrBlock, ID:VpcId}" --output table
done

echo -e "\n⚡ NAT Gateways Activos (Costo crítico):"
for region in us-east-1 us-west-2; do
    aws ec2 describe-nat-gateways --region $region --filter "Name=tag:Project,Values=finnow-drx" \
        --query "NatGateways[*].{ID:NatGatewayId, State:State, IP:NatGatewayAddresses[0].PublicIp}" --output table
done
