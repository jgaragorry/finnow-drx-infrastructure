# 📘 FinNow DRX — Master Runbook

<div align="center">

![FinNow Banner](https://img.shields.io/badge/FinNow-Master%20Runbook-0066FF?style=for-the-badge&logo=amazon-aws&logoColor=white)

[![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-DRY%20Orchestration-40B0A6?style=for-the-badge&logo=terraform&logoColor=white)](https://terragrunt.gruntwork.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--Region-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Regions](https://img.shields.io/badge/Regions-us--east--1%20%7C%20us--west--2-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)]()
[![DR Strategy](https://img.shields.io/badge/DR-Warm%20Standby-F59E0B?style=for-the-badge&logo=amazonec2&logoColor=white)]()

<br/>

> Guía definitiva de despliegue, operación y destrucción controlada de la infraestructura FinNow.  
> Diseñada para ser seguida **paso a paso**, incluso sin experiencia previa en AWS.

</div>

---

## 🗺️ Mapa General del Runbook
```mermaid
flowchart LR
    P0("🔐 FASE 0\nPreparación\ny Auth")
    P1("🌐 FASE 1\nRed\nVPC")
    P2("🐘 FASE 2\nDatos\nRDS")
    P3("🚀 FASE 3\nApp &\nBalanceo")
    P4("💣 FASE 4\nDestroy\nFinOps")
    P5("🔍 FASE 5\nAuditoría\nForense")

    P0 --> P1 --> P2 --> P3
    P3 -.->|"Teardown"| P4 --> P5

    style P0 fill:#1e1b4b,stroke:#6366f1,color:#e0e7ff
    style P1 fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
    style P2 fill:#1a1a2e,stroke:#818cf8,color:#c7d2fe
    style P3 fill:#0c2013,stroke:#16a34a,color:#bbf7d0
    style P4 fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style P5 fill:#1c1917,stroke:#78716c,color:#d6d3d1
```

> **Regla de oro:** cada fase tiene una dependencia estricta de la anterior. No saltes pasos.

---

## 🔐 FASE 0 — Preparación y Autenticación

> *"Tu pasaporte para hablar con AWS. Sin esto, ningún comando funciona."*
```mermaid
flowchart TD
    A(["▶️ Inicio"]) --> B{"¿Herramientas\ninstaladas?"}
    B -- "❌ No" --> C["Instalar:\nTerraform · Terragrunt · AWS CLI"]
    C --> B
    B -- "✅ Sí" --> D["aws configure"]
    D --> E["Ingresar:\nAccess Key ID\nSecret Access Key\nRegión: us-east-1"]
    E --> F["aws sts get-caller-identity"]
    F --> G{"¿Devuelve\ntu Account ID?"}
    G -- "❌ No" --> D
    G -- "✅ Sí" --> H(["✅ Entorno listo"])

    style A fill:#312e81,stroke:#6366f1,color:#e0e7ff
    style H fill:#14532d,stroke:#16a34a,color:#bbf7d0
    style B fill:#1e293b,stroke:#475569,color:#cbd5e1
    style G fill:#1e293b,stroke:#475569,color:#cbd5e1
    style C fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style D fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
    style E fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
    style F fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
```

### Checklist de Prerequisitos

| Herramienta | Versión Mínima | Verificar con |
|---|---|---|
| Terraform | `>= 1.5.0` | `terraform -version` |
| Terragrunt | `>= 0.55.0` | `terragrunt -version` |
| AWS CLI | `>= 2.x` | `aws --version` |
| Infracost | `>= 0.10.x` | `infracost --version` |
```bash
# Verificar identidad y permisos antes de cualquier despliegue
aws sts get-caller-identity
# Resultado esperado: Account ID, ARN y UserId — si falla, revisar credenciales
```

---

## 🌐 FASE 1 — Red (VPC · El Terreno)

> *"Construimos el terreno antes que la casa. Define el espacio lógico seguro donde vivirá toda la infraestructura."*

**Dependencias:** Ninguna. Es el primer paso de infraestructura.
```mermaid
flowchart TD
    VPC["🏠 VPC\n10.0.0.0/16"]

    VPC --> IGW["🌐 Internet Gateway\nPuerta de entrada pública"]
    VPC --> PUB["🟢 Subred PÚBLICA\nPara ALBs únicamente"]
    VPC --> PRIV["🔒 Subred PRIVADA\nPara EC2 · Sin IP pública"]
    VPC --> DATA["🔴 Subred DATOS\nAislada · Solo RDS"]

    IGW --> PUB
    PUB --> NAT["🔁 NAT Gateway\nPermite salida a internet\ndesde subredes privadas"]
    NAT --> PRIV
    PRIV -.->|"Sin acceso\ndirecto"| DATA

    style VPC fill:#1e3a5f,stroke:#3b82f6,color:#bfdbfe
    style IGW fill:#0c1a2e,stroke:#0ea5e9,color:#bae6fd
    style PUB fill:#14532d,stroke:#22c55e,color:#bbf7d0
    style PRIV fill:#312e81,stroke:#6366f1,color:#e0e7ff
    style DATA fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style NAT fill:#1c1917,stroke:#a8a29e,color:#d6d3d1
```

### Despliegue
```bash
# Primero: Región Principal
cd terragrunt/us-east-1/vpc
terragrunt apply -auto-approve

# Segundo: Región DR (misma estructura, aislada)
cd terragrunt/us-west-2/vpc
terragrunt apply -auto-approve
```

### ✅ Validación
```bash
# Confirmar que la VPC y subredes existen en ambas regiones
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,State:State}'
aws ec2 describe-vpcs --region us-west-2 --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,State:State}'
```

---

## 🐘 FASE 2 — Datos (RDS · La Caja Fuerte)

> *"Los datos son el activo más crítico. El Master va primero, la Réplica después — nunca al revés."*

**Dependencias:** ✅ FASE 1 completa en **ambas** regiones.
```mermaid
sequenceDiagram
    participant OPS as 👤 Operador
    participant E1 as 🏢 us-east-1<br/>(Primary)
    participant W2 as 🛡️ us-west-2<br/>(DR)

    OPS->>E1: terragrunt apply (us-east-1/rds)
    E1-->>E1: ✅ RDS Master creado<br/>(Read / Write)
    E1-->>OPS: Exporta: replica_source_arn

    OPS->>W2: terragrunt apply (us-west-2/rds)
    Note over W2: Usa replica_source_arn<br/>del Master como fuente
    W2-->>W2: ✅ RDS Réplica creada<br/>(Read Only)

    loop Operación continua
        E1->>W2: Replicación asíncrona WAL
        W2-->>W2: Réplica sincronizada
    end
```

### Despliegue
```bash
# ⚠️ CRÍTICO: El Master SIEMPRE primero
cd terragrunt/us-east-1/rds
terragrunt apply -auto-approve
# Esperar confirmación: aws_db_instance.this: Creation complete

# Solo después desplegar la Réplica
cd terragrunt/us-west-2/rds
terragrunt apply -auto-approve
```

### ✅ Validación
```bash
# Verificar estado de ambas instancias
aws rds describe-db-instances \
  --region us-east-1 \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Role:ReadReplicaSourceDBInstanceIdentifier}'

aws rds describe-db-instances \
  --region us-west-2 \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}'
# Status esperado: "available" en ambas
```

---

## 🚀 FASE 3 — Aplicación & Balanceo (APP + ALB · La Tienda)

> *"Los servidores y el balanceador. Los usuarios nunca tocan la app directamente — el ALB es el único punto de contacto."*

**Dependencias:** ✅ FASE 1 (VPC) + ✅ FASE 2 (RDS) completas en ambas regiones.
```mermaid
flowchart TD
    USER(["👤 Usuario Final\n(Internet)"])

    subgraph PUBLIC["🟢 Subred Pública"]
        ALB["⚖️ ALB\nPuerto 80\nInternet-Facing"]
    end

    subgraph PRIVATE["🔒 Subred Privada"]
        EC2["🖥️ EC2 t3.nano\nAplicación\nSin IP pública"]
    end

    subgraph DATA["🔴 Subred Datos"]
        RDS[("🐘 RDS PostgreSQL\nPuerto 5432\nSolo acepta EC2")]
    end

    USER -->|"HTTP :80"| ALB
    ALB -->|"Health Check\n+ Forward"| EC2
    EC2 -->|"SQL :5432"| RDS

    style USER fill:#0f172a,stroke:#334155,color:#94a3b8
    style PUBLIC fill:#14532d,stroke:#22c55e,color:#bbf7d0
    style PRIVATE fill:#1e3a5f,stroke:#3b82f6,color:#bfdbfe
    style DATA fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style ALB fill:#0c2013,stroke:#16a34a,color:#bbf7d0
    style EC2 fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
    style RDS fill:#1a1a2e,stroke:#818cf8,color:#c7d2fe
```

### Despliegue
```bash
# Virginia — Primary
cd terragrunt/us-east-1/alb && terragrunt apply -auto-approve
cd terragrunt/us-east-1/app && terragrunt apply -auto-approve

# Oregon — DR (Warm Standby)
cd terragrunt/us-west-2/alb && terragrunt apply -auto-approve
cd terragrunt/us-west-2/app && terragrunt apply -auto-approve
```

### ✅ Validación de Endpoints
```bash
# Health check directo a ambos ALBs
curl -s http://finnow-alb-primary-140854010.us-east-1.elb.amazonaws.com/health
curl -s http://finnow-alb-dr-1428542333.us-west-2.elb.amazonaws.com/health
# Respuesta esperada: HTTP 200 OK
```

---

## 💣 FASE 4 — Destroy Controlado (FinOps · Nuke)

> *"Un recurso olvidado en AWS sigue cobrando. Esta fase es tan importante como el despliegue."*  
> **Filosofía FinOps:** destruir primero lo más caro (RDS → NAT → resto).
```mermaid
flowchart TD
    START(["⚠️ Inicio Teardown"]) --> BYPASS["1️⃣ Aplicar bypass HCL\nen terragrunt.hcl\n(evita errores de carpeta)"]
    BYPASS --> RDS["2️⃣ Borrar RDS Primario\naws rds delete-db-instance\n--skip-final-snapshot"]
    RDS --> REPLICA["3️⃣ Borrar RDS Réplica\n(us-west-2)"]
    REPLICA --> NAT["4️⃣ Borrar NAT Gateways\naws ec2 delete-nat-gateway\n(ambas regiones)"]
    NAT --> TG["5️⃣ terragrunt destroy\nen cascada\n(app → alb → vpc)"]
    TG --> AUDIT{"6️⃣ ¿Quedan\nrecursos?"}
    AUDIT -- "✅ No" --> ZERO(["💚 Cuenta en $0"])
    AUDIT -- "❌ Sí" --> MANUAL["Borrado manual CLI\n(ver comandos abajo)"]
    MANUAL --> AUDIT

    style START fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style ZERO fill:#14532d,stroke:#16a34a,color:#bbf7d0
    style AUDIT fill:#1e293b,stroke:#475569,color:#cbd5e1
    style MANUAL fill:#78350f,stroke:#d97706,color:#fef3c7
    style RDS fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style REPLICA fill:#3b0a0a,stroke:#dc2626,color:#fecaca
    style NAT fill:#78350f,stroke:#d97706,color:#fef3c7
```

### Orden de Destrucción
```bash
# ── PASO 1: RDS Primario (lo más caro — $11.68/mo)
aws rds delete-db-instance \
  --db-instance-identifier finnow-rds-primary \
  --skip-final-snapshot \
  --region us-east-1

# ── PASO 2: RDS Réplica
aws rds delete-db-instance \
  --db-instance-identifier finnow-rds-replica \
  --skip-final-snapshot \
  --region us-west-2

# ── PASO 3: NAT Gateways (buscar IDs primero)
aws ec2 describe-nat-gateways --region us-east-1 \
  --query 'NatGateways[*].{ID:NatGatewayId,State:State}'
aws ec2 delete-nat-gateway --nat-gateway-id <ID> --region us-east-1
aws ec2 delete-nat-gateway --nat-gateway-id <ID> --region us-west-2

# ── PASO 4: Terragrunt destroy en cascada (orden inverso al despliegue)
cd terragrunt/us-east-1/app   && terragrunt destroy -auto-approve
cd terragrunt/us-east-1/alb   && terragrunt destroy -auto-approve
cd terragrunt/us-east-1/vpc   && terragrunt destroy -auto-approve
cd terragrunt/us-west-2/app   && terragrunt destroy -auto-approve
cd terragrunt/us-west-2/alb   && terragrunt destroy -auto-approve
cd terragrunt/us-west-2/vpc   && terragrunt destroy -auto-approve
```

---

## 🔍 FASE 5 — Auditoría Forense Final

> *"Los recursos 'zombie' son silenciosos y costosos. Esta auditoría garantiza que la cuenta llega a $0."*
```mermaid
flowchart LR
    SCRIPT["./scripts/\nforensic_cleanup_check.sh"] --> NAT_C["NAT Gateways\n¿Resultado vacío?"]
    SCRIPT --> RDS_C["RDS Instances\n¿Resultado vacío?"]
    SCRIPT --> ALB_C["Load Balancers\n¿Resultado vacío?"]
    SCRIPT --> EC2_C["EC2 Instances\n¿Estado: terminated?"]
    SCRIPT --> EIP_C["Elastic IPs\n¿Resultado vacío?"]

    NAT_C --> OK{"✅ Todo\nlimpio?"}
    RDS_C --> OK
    ALB_C --> OK
    EC2_C --> OK
    EIP_C --> OK

    OK -- "✅ Sí" --> DONE(["💚 $0 — Auditoría\naprobada"])
    OK -- "❌ No" --> KILL["Borrado manual\ndel recurso zombie"]
    KILL --> SCRIPT

    style SCRIPT fill:#1e1b4b,stroke:#6366f1,color:#e0e7ff
    style DONE fill:#14532d,stroke:#16a34a,color:#bbf7d0
    style OK fill:#1e293b,stroke:#475569,color:#cbd5e1
    style KILL fill:#3b0a0a,stroke:#dc2626,color:#fecaca
```

### Comandos de Auditoría
```bash
# Ejecutar script completo
./scripts/forensic_cleanup_check.sh

# — O manualmente, recurso por recurso —

# NAT Gateways (resultado esperado: vacío o "deleted")
aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query 'NatGateways[*].NatGatewayId' \
  --region us-east-1
aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query 'NatGateways[*].NatGatewayId' \
  --region us-west-2

# RDS (resultado esperado: vacío)
aws rds describe-db-instances \
  --query 'DBInstances[*].DBInstanceIdentifier' \
  --region us-east-1
aws rds describe-db-instances \
  --query 'DBInstances[*].DBInstanceIdentifier' \
  --region us-west-2

# Load Balancers (resultado esperado: vacío)
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].LoadBalancerArn' \
  --region us-east-1
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].LoadBalancerArn' \
  --region us-west-2

# EC2 (resultado esperado: "terminated")
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}' \
  --region us-east-1
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}' \
  --region us-west-2

# Elastic IPs (resultado esperado: vacío)
aws ec2 describe-addresses --query 'Addresses[*].PublicIp' --region us-east-1
aws ec2 describe-addresses --query 'Addresses[*].PublicIp' --region us-west-2
```

### ✅ Checklist Final del Evaluador

| Recurso | Región | Resultado Esperado | Estado |
|---|---|---|---|
| NAT Gateways | `us-east-1` | `[]` vacío | `[ ]` |
| NAT Gateways | `us-west-2` | `[]` vacío | `[ ]` |
| RDS Instances | `us-east-1` | `[]` vacío | `[ ]` |
| RDS Instances | `us-west-2` | `[]` vacío | `[ ]` |
| Load Balancers | `us-east-1` | `[]` vacío | `[ ]` |
| Load Balancers | `us-west-2` | `[]` vacío | `[ ]` |
| EC2 Instances | `us-east-1` | `"terminated"` | `[ ]` |
| EC2 Instances | `us-west-2` | `"terminated"` | `[ ]` |
| Elastic IPs | `us-east-1` | `[]` vacío | `[ ]` |
| Elastic IPs | `us-west-2` | `[]` vacío | `[ ]` |

---

<div align="center">

**Built with precision by [gmt (Jose)](https://github.com/gmt)**

[![Back to README](https://img.shields.io/badge/←%20README-Principal-232F3E?style=flat-square&logo=amazon-aws)](./README.md)
[![Infracost Report](https://img.shields.io/badge/💰%20Infracost-Report-1DB954?style=flat-square)](./INFRACOST.md)

*"Un buen runbook es el que puede seguir alguien a las 3am durante un incidente."*

</parameter>

</div>
