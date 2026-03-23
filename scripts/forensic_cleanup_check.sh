#!/bin/bash
# ==============================================================================
# SCRIPT: forensic_cleanup_check.sh (Versión Senior Pro)
# OBJETIVO: Auditoría exhaustiva para CERO facturación post-laboratorio.
# ==============================================================================

PROJECT_TAG="finnow-drx"
REGIONS=("us-east-1" "us-west-2")

echo "🔍 INICIANDO AUDITORÍA FORENSE DE COSTOS (TOTAL CLEANUP)..."

for REGION in "${REGIONS[@]}"; do
    echo -e "\n🌎 REVISANDO REGIÓN: $REGION"
    echo "-------------------------------------------------------"

    # 1. Red y Conectividad (Lo más crítico en costos fijos)
    echo "⚡ NAT Gateways (Disponibles/Pendientes):"
    aws ec2 describe-nat-gateways --region $REGION \
        --filter "Name=state,Values=pending,available" \
        --query "NatGateways[*].{ID:NatGatewayId,State:State}" --output table

    echo "📍 Elastic IPs (Sin asociación):"
    aws ec2 describe-addresses --region $REGION \
        --query "Addresses[?AssociationId==null].{IP:PublicIp,AllocationId:AllocationId}" --output table

    # 2. Cómputo y Balanceo
    echo "⚖️ Load Balancers (ALB/NLB):"
    aws elbv2 describe-load-balancers --region $REGION \
        --query "LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}" --output table

    echo "🖥️  Instancias EC2 (Cualquier estado excepto Terminated):"
    aws ec2 describe-instances --region $REGION \
        --filters "Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped" \
        --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}" --output table

    # 3. Almacenamiento (Zombies silenciosos de facturación)
    echo "💾 Volúmenes EBS Huérfanos (Available):"
    aws ec2 describe-volumes --region $REGION \
        --filters "Name=status,Values=available" \
        --query "Volumes[*].{ID:VolumeId,Size:Size,Type:VolumeType}" --output table

    echo "📸 Snapshots de EBS (Creados por el usuario):"
    aws ec2 describe-snapshots --region $REGION --owner-ids self \
        --query "Snapshots[*].{ID:SnapshotId,Volume:VolumeId,StartTime:StartTime}" --output table

    # 4. Bases de Datos y Persistencia
    echo "🐘 Instancias RDS Activas:"
    aws rds describe-db-instances --region $REGION \
        --query "DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}" --output table

    echo "📑 RDS Snapshots (Backups manuales/residuales):"
    aws rds describe-db-snapshots --region $REGION \
        --query "DBSnapshots[*].{ID:DBSnapshotIdentifier,Status:Status}" --output table

    # 5. Observabilidad (Logs que acumulan costos de storage)
    echo "📝 Grupos de Logs en CloudWatch (/aws/lambda/ o /aws/rds/):"
    aws logs describe-log-groups --region $REGION \
        --query "logGroups[?contains(logGroupName, '$PROJECT_TAG')].{Name:logGroupName,Size:storedBytes}" --output table

    # 6. Estructura de Red Remanente
    echo "🗺️  VPCs con Tag del Proyecto:"
    aws ec2 describe-vpcs --region $REGION \
        --filters "Name=tag:Project,Values=$PROJECT_TAG" \
        --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}" --output table
done

echo -e "\n✅ Auditoría forense finalizada."
