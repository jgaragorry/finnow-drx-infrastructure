#!/bin/bash
# ==============================================================================
# SCRIPT: nuke_vpc.sh
# DESCRIPCIÓN: Elimina una VPC y todas sus dependencias (Subnets, IGW, RTB).
# USO: ./scripts/nuke_vpc.sh <VPC_ID> <REGION>
# ==============================================================================

VPC_ID=$1
REGION=$2

if [ -z "$VPC_ID" ] || [ -z "$REGION" ]; then
    echo "❌ Uso: $0 <vpc-id> <region>"
    exit 1
fi

echo "☢️ Iniciando desmantelamiento de VPC: $VPC_ID en $REGION..."

# 1. Eliminar Internet Gateways
IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].InternetGatewayId" --output text)
for IGW in $IGWS; do
    echo "  🔌 Detach y borrado de IGW: $IGW"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION
done

# 2. Eliminar Subnets
SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text)
for SUBNET in $SUBNETS; do
    echo "  📦 Borrando Subnet: $SUBNET"
    aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION
done

# 3. Eliminar Route Tables (excepto la principal)
RTBS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[0].Main!=true].RouteTableId" --output text)
for RTB in $RTBS; do
    echo "  🛣️ Borrando Route Table: $RTB"
    aws ec2 delete-route-table --route-table-id $RTB --region $REGION
done

# 4. Eliminar Security Groups (excepto el default)
SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
for SG in $SGS; do
    echo "  🛡️ Borrando Security Group: $SG"
    aws ec2 delete-security-group --group-id $SG --region $REGION
done

# 5. Finalmente, borrar la VPC
echo "  🗑️ Borrando VPC final..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

echo "✅ VPC $VPC_ID eliminada exitosamente."
