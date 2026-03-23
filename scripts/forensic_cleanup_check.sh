#!/bin/bash
# ==============================================================================
# SCRIPT: forensic_cleanup_check.sh
# OBJETIVO: Cero recursos facturables después del laboratorio.
# ==============================================================================

PROJECT_TAG="finnow-drx"
REGIONS=("us-east-1" "us-west-2")

echo "🔍 INICIANDO AUDITORÍA FORENSE DE COSTOS..."

for REGION in "${REGIONS[@]}"; do
    echo -e "\n🌎 REVISANDO REGIÓN: $REGION"
    echo "-------------------------------------------------------"

    # 1. NAT Gateways (Lo más caro)
    echo "⚡ NAT Gateways:"
    aws ec2 describe-nat-gateways --region $REGION \
        --filter "Name=state,Values=pending,available" \
        --query "NatGateways[*].{ID:NatGatewayId,State:State}" --output table

    # 2. Elastic IPs (Cobran si no están asociadas)
    echo "📍 Elastic IPs (Unassociated):"
    aws ec2 describe-addresses --region $REGION \
        --query "Addresses[?AssociationId==null].{IP:PublicIp,AllocationId:AllocationId}" --output table

    # 3. RDS Instances (Si llegamos a crear alguna)
    echo "🐘 Instancias RDS:"
    aws rds describe-db-instances --region $REGION \
        --query "DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}" --output table

    # 4. Load Balancers
    echo "⚖️ ELB / ALBs:"
    aws elbv2 describe-load-balancers --region $REGION \
        --query "LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName}" --output table

    # 5. VPCs del proyecto
    echo "🗺️ VPCs remanentes del proyecto:"
    aws ec2 describe-vpcs --region $REGION \
        --filters "Name=tag:Project,Values=$PROJECT_TAG" \
        --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}" --output table
done

echo -e "\n✅ Auditoría finalizada."
