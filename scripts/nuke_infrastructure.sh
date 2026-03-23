#!/bin/bash

# Configuración de Colores para el usuario inquieto
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==============================================================${NC}"
echo -e "${BLUE}   FINNOW DRX - DESTRUCT-O-MATIC PRO (FINOPS EDITION)         ${NC}"
echo -e "${BLUE}==============================================================${NC}"

REGIONS=("us-east-1" "us-west-2")

for REGION in "${REGIONS[@]}"; do
    echo -e "\n${YELLOW}🌎 PROCESANDO REGIÓN: $REGION${NC}"
    echo "-------------------------------------------------------"

    # 1. ELIMINACIÓN DE APP (EC2)
    echo -e "${YELLOW}[1/5] Terminando Instancias EC2...${NC}"
    INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=tag:Project,Values=finnow-drx" "Name=instance-state-name,Values=running,pending,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text)
    
    if [ ! -z "$INSTANCES" ]; then
        aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCES > /dev/null
        echo -e "${BLUE}⏳ Esperando que EC2 pase a estado 'terminated'...${NC}"
        aws ec2 wait instance-terminated --region $REGION --instance-ids $INSTANCES
        echo -e "${GREEN}✅ Instancias eliminadas.${NC}"
    else
        echo "No hay instancias activas."
    fi

    # 2. ELIMINACIÓN DE ALB
    echo -e "${YELLOW}[2/5] Eliminando Load Balancer...${NC}"
    ALB_ARN=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName, 'finnow')].LoadBalancerArn" --output text)
    
    if [ ! -z "$ALB_ARN" ]; then
        aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn $ALB_ARN
        echo -e "${BLUE}⏳ Esperando liberación de Interfaces de Red del ALB (60s)...${NC}"
        # El ALB no tiene un 'wait' nativo para borrado total de ENIs, aplicamos sleep prudencial
        sleep 60
        echo -e "${GREEN}✅ ALB solicitado y tiempo de gracia cumplido.${NC}"
    else
        echo "No se encontró ALB."
    fi

    # 3. ELIMINACIÓN DE RDS (EL MÁS CRÍTICO)
    echo -e "${YELLOW}[3/5] Eliminando Base de Datos RDS (Sin Snapshot)...${NC}"
    RDS_ID=$(aws rds describe-db-instances --region $REGION --query "DBInstances[?DBInstanceIdentifier=='finnow-db-primary' || DBInstanceIdentifier=='finnow-db-replica'].DBInstanceIdentifier" --output text)
    
    if [ ! -z "$RDS_ID" ]; then
        aws rds delete-db-instance --region $REGION --db-instance-identifier $RDS_ID --skip-final-snapshot --delete-automated-backups > /dev/null
        echo -e "${BLUE}⏳ Monitoreando RDS: Entrando en estado 'deleting'...${NC}"
        
        # Bucle de monitoreo real
        while true; do
            STATUS=$(aws rds describe-db-instances --region $REGION --db-instance-identifier $RDS_ID --query "DBInstances[0].DBInstanceStatus" --output text 2>/dev/null)
            if [ $? -ne 0 ] || [ -z "$STATUS" ]; then
                echo -e "\n${GREEN}✅ La base de datos ha desaparecido de la API.${NC}"
                break
            fi
            echo -ne "${YELLOW}Estado actual: [$STATUS]... Reintentando en 20s \r${NC}"
            sleep 20
        done
    else
        echo "No hay RDS activo."
    fi

    # 4. ELIMINACIÓN DE NAT GATEWAY (BLOQUEADOR DE VPC)
    echo -e "${YELLOW}[4/5] Eliminando NAT Gateways...${NC}"
    NAT_IDS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=state,Values=available" --query "NatGateways[*].NatGatewayId" --output text)
    
    for NAT in $NAT_IDS; do
        aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $NAT > /dev/null
        echo -e "${BLUE}⏳ Esperando que NAT $NAT sea purgado de la red...${NC}"
        while true; do
            NAT_STATUS=$(aws ec2 describe-nat-gateways --region $REGION --nat-gateway-ids $NAT --query "NatGateways[0].State" --output text)
            if [ "$NAT_STATUS" == "deleted" ]; then
                break
            fi
            echo -ne "${YELLOW}Estado NAT: [$NAT_STATUS]... (esto toma tiempo) \r${NC}"
            sleep 15
        done
    done
    echo -e "${GREEN}✅ Red liberada de NAT Gateways.${NC}"

    # 5. DESTRUCCIÓN DE VPC (FINAL)
    echo -e "${YELLOW}[5/5] Ejecutando Terragrunt Destroy Final para limpiar VPC y SG...${NC}"
    # Forzamos un pequeño respiro para que las ENIs se desasocien de las subredes
    sleep 30
    
    cd terragrunt/$REGION/vpc
    terragrunt destroy -auto-approve -refresh=false
    cd ../../../
    
    echo -e "${GREEN}⭐ REGIÓN $REGION COMPLETADA.${NC}"
done

echo -e "${BLUE}==============================================================${NC}"
echo -e "${GREEN}   PROCESO FINALIZADO: CUENTA EN ESTADO FINOPS SEGURO         ${NC}"
echo -e "${BLUE}==============================================================${NC}"

# Ejecutar auditoría final automáticamente
./scripts/forensic_cleanup_check.sh
