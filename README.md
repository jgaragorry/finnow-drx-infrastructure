# FinNow — Multi-Region Resilient Infrastructure

<div align="center">

![FinNow Banner](https://img.shields.io/badge/FinNow-Multi--Region%20IaC-0066FF?style=for-the-badge&logo=amazon-aws&logoColor=white)

[![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-DRY%20Orchestration-40B0A6?style=for-the-badge&logo=terraform&logoColor=white)](https://terragrunt.gruntwork.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--Region-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Infracost](https://img.shields.io/badge/Infracost-%24124.02%2Fmo-1DB954?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnoiIGZpbGw9IndoaXRlIi8+PC9zdmc+&logoColor=white)](https://www.infracost.io/)
[![Security](https://img.shields.io/badge/Security-Defense%20in%20Depth-DC2626?style=for-the-badge&logo=shield&logoColor=white)]()
[![DR Strategy](https://img.shields.io/badge/DR-Warm%20Standby-F59E0B?style=for-the-badge&logo=amazonec2&logoColor=white)]()
[![IMDSv2](https://img.shields.io/badge/IMDSv2-Enforced-16A34A?style=for-the-badge&logo=amazonaws&logoColor=white)]()
[![License](https://img.shields.io/badge/License-MIT-6366F1?style=for-the-badge)]()

<br/>

> **Production-grade, battle-tested IaC for a Fintech platform.**  
> Architected with **Defense-in-Depth security**, **3-Tier isolation**, and a **Warm-Standby DR strategy** spanning two AWS regions.

<br/>

[![Primary ALB](https://img.shields.io/badge/🟢%20Live%20API%20Virginia-us--east--1-232F3E?style=flat-square&logo=amazon-aws)](http://finnow-alb-primary-140854010.us-east-1.elb.amazonaws.com)
[![DR ALB](https://img.shields.io/badge/🟡%20DR%20API%20Oregon-us--west--2-232F3E?style=flat-square&logo=amazon-aws)](http://finnow-alb-dr-1428542333.us-west-2.elb.amazonaws.com)

</div>

---

## 📐 Architecture Overview
```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        U[("👤 End Users")]
    end

    subgraph Primary["🏢 us-east-1 — Primary Region"]
        direction TB
        subgraph T1_P["Tier 1 · Public — Presentation"]
            ALB_P["⚖️ ALB Primary\n(Internet-Facing)"]
        end
        subgraph T2_P["Tier 2 · Private — Application"]
            EC2_P["🖥️ EC2 Fleet\n(t3.nano · Private Subnet)"]
        end
        subgraph T3_P["Tier 3 · Isolated — Data"]
            RDS_P[("🐘 RDS PostgreSQL\nPrimary Instance\nt4g.micro · Graviton")]
        end
        ALB_P -- "Port 80" --> EC2_P
        EC2_P -- "Port 5432" --> RDS_P
    end

    subgraph DR["🛡️ us-west-2 — DR Region (Warm Standby)"]
        direction TB
        subgraph T1_D["Tier 1 · Public — Presentation"]
            ALB_D["⚖️ ALB DR\n(Internet-Facing)"]
        end
        subgraph T2_D["Tier 2 · Private — Application"]
            EC2_D["🖥️ EC2 Fleet\n(t3.nano · Private Subnet)"]
        end
        subgraph T3_D["Tier 3 · Isolated — Data"]
            RDS_D[("🐘 RDS PostgreSQL\nRead Replica\nt4g.micro · Graviton")]
        end
        ALB_D -- "Port 80" --> EC2_D
        EC2_D -- "Port 5432" --> RDS_D
    end

    U --> ALB_P
    U -.->|"Failover"| ALB_D
    RDS_P -->|"🔁 Cross-Region\nAsynchronous Replication"| RDS_D

    style Internet fill:#0f172a,color:#94a3b8,stroke:#334155
    style Primary fill:#0c1a2e,color:#93c5fd,stroke:#1d4ed8
    style DR fill:#0c2013,color:#86efac,stroke:#15803d
    style T1_P fill:#1e3a5f,stroke:#3b82f6,color:#bfdbfe
    style T2_P fill:#1e2d3d,stroke:#0ea5e9,color:#bae6fd
    style T3_P fill:#1a1a2e,stroke:#6366f1,color:#c7d2fe
    style T1_D fill:#14532d,stroke:#22c55e,color:#bbf7d0
    style T2_D fill:#1c3829,stroke:#4ade80,color:#bbf7d0
    style T3_D fill:#0f2318,stroke:#16a34a,color:#bbf7d0
```

---

## 🔒 Security Architecture — Defense in Depth
```mermaid
graph LR
    subgraph SG_ALB["🛡️ SG: alb-sg"]
        R1["Inbound: 0.0.0.0/0 → 80/tcp"]
        R2["Outbound: → App Tier SG"]
    end
    subgraph SG_APP["🛡️ SG: app-sg"]
        R3["Inbound: ALB SG → 80/tcp ONLY"]
        R4["Outbound: → Data Tier SG"]
        R5["Zero Public IP Enforced ✅"]
        R6["IMDSv2 Enforced ✅"]
    end
    subgraph SG_RDS["🛡️ SG: rds-sg"]
        R7["Inbound: App SG → 5432/tcp ONLY"]
        R8["No Internet Route ✅"]
    end

    SG_ALB --> SG_APP --> SG_RDS

    style SG_ALB fill:#1e1b4b,stroke:#6366f1,color:#c7d2fe
    style SG_APP fill:#1c2942,stroke:#3b82f6,color:#bfdbfe
    style SG_RDS fill:#1a1a2e,stroke:#818cf8,color:#e0e7ff
```

| Control | Implementation | Status |
|---|---|---|
| **Zero Public IP** | EC2 instances deployed in private subnets only | ✅ Enforced |
| **IMDSv2** | `http_tokens = required` on all launch templates | ✅ Enforced |
| **Least Privilege SGs** | Port-scoped rules, no `0.0.0.0/0` on compute/data tiers | ✅ Enforced |
| **Network Isolation** | 3 isolated subnets per AZ (public/private/data) | ✅ Enforced |
| **Encryption at Rest** | RDS storage encryption enabled | ✅ Enforced |
| **Cross-Region Replication** | Automated read replica with async replication | ✅ Active |

---

## 🌎 Disaster Recovery Strategy
```mermaid
sequenceDiagram
    participant OPS as 👤 Operator
    participant R1 as 🏢 us-east-1 (Primary)
    participant REP as 🔁 Replication Layer
    participant R2 as 🛡️ us-west-2 (Warm Standby)

    Note over R1,R2: Normal Operations
    R1->>REP: Continuous WAL / Binlog Stream
    REP-->>R2: Async Cross-Region Replication
    R2-->>R2: Read Replica in Sync

    Note over OPS,R2: Failure Scenario
    OPS->>R1: ❌ Region degradation detected
    OPS->>R2: Promote Read Replica → Primary
    R2-->>R2: ✅ RDS now writable
    OPS->>R2: Point application traffic to DR ALB
    R2-->>OPS: 🟢 DR Region fully operational

    Note over R1,R2: Recovery Objectives
    R1--xR1: RPO: minutes (async replication lag)
    R2-->>R2: RTO: < 30 min (warm standby, pre-provisioned)
```

| Metric | Target | Strategy |
|---|---|---|
| **RPO** (Recovery Point Objective) | Minutes | Async cross-region RDS replication |
| **RTO** (Recovery Time Objective) | < 30 min | Warm Standby — infrastructure pre-provisioned |
| **DR Activation** | Manual promotion | Promote read replica + redirect ALB DNS |
| **Data Consistency** | Eventually consistent | PostgreSQL asynchronous streaming replication |

---

## 🏗️ Infrastructure Components
```mermaid
graph TD
    TG["📦 Terragrunt\nOrchestrator (DRY)"]

    TG --> MOD["🧩 _modules/"]
    MOD --> M_VPC["vpc/\nVPC · Subnets · IGW · NAT"]
    MOD --> M_ALB["alb/\nALB · Target Groups · Listeners"]
    MOD --> M_APP["app/\nLaunch Template · ASG · SG"]
    MOD --> M_RDS["rds/\nPostgreSQL · Parameter Groups · SG"]

    TG --> EAST["🏢 us-east-1/"]
    EAST --> E_VPC["vpc/\n3-Tier Subnet Layout"]
    EAST --> E_ALB["alb/\nInternet-Facing"]
    EAST --> E_APP["app/\nt3.nano · Private Subnets"]
    EAST --> E_RDS["rds/\nPrimary Instance · t4g.micro"]

    TG --> WEST["🛡️ us-west-2/"]
    WEST --> W_VPC["vpc/\n3-Tier Subnet Layout"]
    WEST --> W_ALB["alb/\nInternet-Facing DR"]
    WEST --> W_APP["app/\nt3.nano · Private Subnets"]
    WEST --> W_RDS["rds/\nRead Replica · t4g.micro"]

    style TG fill:#312e81,stroke:#6366f1,color:#e0e7ff
    style MOD fill:#1e1b4b,stroke:#818cf8,color:#c7d2fe
    style EAST fill:#0c1a2e,stroke:#3b82f6,color:#bfdbfe
    style WEST fill:#0c2013,stroke:#16a34a,color:#bbf7d0
```

---

## 📁 Repository Structure
```text
finnow-infrastructure/
│
├── terragrunt/
│   ├── _modules/                    # 🧩 Reusable Terraform base modules
│   │   ├── vpc/                     #    VPC, Subnets, IGW, NAT Gateway, Route Tables
│   │   ├── alb/                     #    Application Load Balancer, Target Groups
│   │   ├── app/                     #    EC2 Launch Template, ASG, Security Groups
│   │   └── rds/                     #    RDS PostgreSQL, Parameter Groups, Subnet Groups
│   │
│   ├── us-east-1/                   # 🏢 Primary Region — Virginia
│   │   ├── terragrunt.hcl           #    Region-level config & remote state
│   │   ├── vpc/terragrunt.hcl
│   │   ├── alb/terragrunt.hcl
│   │   ├── app/terragrunt.hcl
│   │   └── rds/terragrunt.hcl
│   │
│   └── us-west-2/                   # 🛡️ DR Region — Oregon
│       ├── terragrunt.hcl           #    Region-level config & remote state
│       ├── vpc/terragrunt.hcl
│       ├── alb/terragrunt.hcl
│       ├── app/terragrunt.hcl
│       └── rds/terragrunt.hcl       #    Cross-region replica source ARN injected
│
├── .infracost/                      # 💰 FinOps cost estimation config
├── screenshots/                     # 📸 Live deployment validation
└── README.md
```

---

## 💰 FinOps — Cost Analysis

> Estimated via **Infracost** based on `us-east-1` on-demand pricing.
```mermaid
pie title Monthly Cost Breakdown — $124.02 USD
    "RDS Primary (t4g.micro)" : 28.47
    "RDS Read Replica (t4g.micro)" : 28.47
    "NAT Gateway (× 2 regions)" : 36.50
    "ALB (× 2 regions)" : 18.40
    "EC2 t3.nano fleet" : 7.30
    "Data Transfer & Storage" : 4.88
```

| Resource | Type | Region | Est. Cost/mo |
|---|---|---|---|
| RDS PostgreSQL Primary | `db.t4g.micro` (Graviton) | `us-east-1` | ~$28.47 |
| RDS PostgreSQL Replica | `db.t4g.micro` (Graviton) | `us-west-2` | ~$28.47 |
| NAT Gateways | Managed NAT (× 2) | Both | ~$36.50 |
| Application Load Balancers | ALB (× 2) | Both | ~$18.40 |
| EC2 Application Fleet | `t3.nano` | Both | ~$7.30 |
| Storage, Transfer, Misc | — | — | ~$4.88 |
| **Total** | | | **~$124.02** |

> 💡 **FinOps Notes:** Graviton-based `t4g.micro` instances provide up to **40% cost savings** over equivalent x86 instance types with comparable or superior performance for PostgreSQL workloads.

---

## ⚙️ Deployment

### Prerequisites
```bash
# Required toolchain
terraform  >= 1.5.0
terragrunt >= 0.55.0
aws-cli    >= 2.x
infracost  >= 0.10.x  # optional — cost estimation
```

### Bootstrap
```bash
# 1. Configure AWS credentials for both regions
export AWS_PROFILE=finnow-prod

# 2. Deploy Primary Region first
cd terragrunt/us-east-1
terragrunt run-all apply

# 3. Deploy DR Region (depends on primary RDS ARN)
cd terragrunt/us-west-2
terragrunt run-all apply

# 4. Validate endpoints
curl -s http://finnow-alb-primary-140854010.us-east-1.elb.amazonaws.com/health
curl -s http://finnow-alb-dr-1428542333.us-west-2.elb.amazonaws.com/health
```

### Cost Estimation
```bash
# Estimate full infrastructure cost before apply
infracost breakdown --path terragrunt/ --terraform-parse-hcl
```

---

## 🔗 Live Endpoints

| Region | Role | Endpoint |
|---|---|---|
| `us-east-1` | 🟢 Primary | [finnow-alb-primary-140854010.us-east-1.elb.amazonaws.com](http://finnow-alb-primary-140854010.us-east-1.elb.amazonaws.com) |
| `us-west-2` | 🟡 Warm Standby | [finnow-alb-dr-1428542333.us-west-2.elb.amazonaws.com](http://finnow-alb-dr-1428542333.us-west-2.elb.amazonaws.com) |

---

## 🧱 Architecture Decision Records (ADR)

<details>
<summary><strong>ADR-001 · Terragrunt over pure Terraform</strong></summary>

**Context:** Multi-region deployments require managing remote state, provider configs, and cross-region dependencies without code duplication.  
**Decision:** Adopted Terragrunt as the orchestration layer to enforce DRY principles across region-specific deployments.  
**Consequences:** Reduces configuration drift, enforces consistent remote state backends, and enables `run-all` orchestration with dependency graphs.

</details>

<details>
<summary><strong>ADR-002 · Warm Standby over Active-Active or Cold Standby</strong></summary>

**Context:** Active-Active requires synchronous replication and significantly higher cost. Cold standby has unacceptable RTO for Fintech SLAs.  
**Decision:** Warm Standby with asynchronous cross-region RDS replication. Infrastructure is pre-provisioned; only manual DB promotion is required during failover.  
**Consequences:** RTO < 30min, minimal cost overhead, acceptable RPO for the current compliance requirements.

</details>

<details>
<summary><strong>ADR-003 · Graviton (t4g) for RDS workloads</strong></summary>

**Context:** PostgreSQL is CPU and memory-efficient; ARM-based Graviton processors offer better price/performance for this workload profile.  
**Decision:** Use `db.t4g.micro` (Graviton2) for all RDS instances.  
**Consequences:** ~40% cost reduction vs. equivalent Intel x86 instance. RDS fully supports Graviton for PostgreSQL 13+.

</details>

<details>
<summary><strong>ADR-004 · IMDSv2 enforcement</strong></summary>

**Context:** IMDSv1 is vulnerable to SSRF attacks that can expose IAM credentials via the metadata endpoint.  
**Decision:** Enforce `http_tokens = required` (IMDSv2) on all EC2 launch templates.  
**Consequences:** Eliminates SSRF-based credential exfiltration vector. Required by AWS Security Hub FSBP standard.

</details>

---

<div align="center">

**Built with precision by [gmt (Jose)](https://github.com/gmt)**

[![AWS](https://img.shields.io/badge/AWS-Powered-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](https://terraform.io)
[![Terragrunt](https://img.shields.io/badge/Orchestration-Terragrunt-40B0A6?style=flat-square)](https://terragrunt.gruntwork.io)

*"Infrastructure is not just code — it is the foundation of trust in financial systems."*

</div>
