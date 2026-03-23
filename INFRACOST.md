# 💰 FinNow — Infracost Breakdown Report

<div align="center">

[![Infracost](https://img.shields.io/badge/Infracost-Cost%20Analysis-1DB954?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnoiIGZpbGw9IndoaXRlIi8+PC9zdmc+&logoColor=white)](https://www.infracost.io/)
[![Total Cost](https://img.shields.io/badge/Monthly%20Total-%24124.02%20USD-0066FF?style=for-the-badge&logo=amazonaws&logoColor=white)]()
[![Projects](https://img.shields.io/badge/Projects%20Scanned-8-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)]()
[![Resources](https://img.shields.io/badge/Resources%20Detected-80-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)]()
[![Free Resources](https://img.shields.io/badge/Free%20Resources-72-16A34A?style=for-the-badge&logo=amazonaws&logoColor=white)]()

<br/>

> Auto-generated cost breakdown via `infracost breakdown` across **8 Terragrunt root modules**  
> spanning two AWS regions — `us-east-1` (Primary) and `us-west-2` (Warm Standby DR).

</div>

---

## 📊 Cost Summary by Project
```mermaid
xychart-beta
    title "Monthly Cost by Terragrunt Project (USD)"
    x-axis ["us-east-1 ALB", "us-east-1 APP", "us-east-1 RDS", "us-east-1 VPC", "us-west-2 ALB", "us-west-2 APP", "us-west-2 RDS", "us-west-2 VPC"]
    y-axis "Cost (USD)" 0 --> 40
    bar [16.43, 4.60, 13.98, 32.85, 16.43, 4.60, 2.30, 32.85]
```

| Project | Module Path | Baseline Cost | Usage Cost | **Total** |
|---|---|---|---|---|
| `us-east-1-alb` | `us-east-1/alb` | $16.43 | — | **$16** |
| `us-east-1-app` | `us-east-1/app` | $4.60 | — | **$5** |
| `us-east-1-rds` | `us-east-1/rds` | $13.98 | — | **$14** |
| `us-east-1-vpc` | `us-east-1/vpc` | $32.85 | — | **$33** |
| `us-west-2-alb` | `us-west-2/alb` | $16.43 | — | **$16** |
| `us-west-2-app` | `us-west-2/app` | $4.60 | — | **$5** |
| `us-west-2-rds` | `us-west-2/rds` | $2.30 ⚠️ | — | **$2** |
| `us-west-2-vpc` | `us-west-2/vpc` | $32.85 | — | **$33** |
| | | | **OVERALL TOTAL** | **$124.02** |

> ⚠️ `us-west-2-rds`: `aws_db_instance` compute price reported as `not found` by Infracost (known pricing API gap for cross-region read replicas on `db.t4g.micro`). Storage cost of `$2.30` was captured. Actual instance cost mirrors `us-east-1` at ~`$11.68/mo`.

---

## 🔍 Resource-Level Breakdown

### 🏢 us-east-1 — Primary Region

#### Application Load Balancer — `$16.43/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_lb.this` — ALB hours | 730 | hours | $16.43 |
| Load Balancer Capacity Units | usage-based | per LCU | $5.84/LCU |

#### EC2 Application Instance — `$4.60/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_instance.app` — `t3.nano` Linux on-demand | 730 | hours | $3.80 |
| Root EBS volume (`gp2`) | 8 | GB | $0.80 |

#### RDS PostgreSQL Primary — `$13.98/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_db_instance.this` — `db.t4g.micro` Single-AZ | 730 | hours | $11.68 |
| Storage `gp3` | 20 | GB | $2.30 |
| Additional backup storage | usage-based | per GB | $0.095/GB |

#### VPC + NAT Gateway — `$32.85/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_nat_gateway.this[0]` — NAT hours | 730 | hours | $32.85 |
| Data processed | usage-based | per GB | $0.045/GB |

---

### 🛡️ us-west-2 — DR Region (Warm Standby)

#### Application Load Balancer — `$16.43/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_lb.this` — ALB hours | 730 | hours | $16.43 |
| Load Balancer Capacity Units | usage-based | per LCU | $5.84/LCU |

#### EC2 Application Instance — `$4.60/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_instance.app` — `t3.nano` Linux on-demand | 730 | hours | $3.80 |
| Root EBS volume (`gp2`) | 8 | GB | $0.80 |

#### RDS PostgreSQL Read Replica — `$2.30/mo` ⚠️

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_db_instance.this` — `db.t4g.micro` Single-AZ | 730 | hours | `not found` ⚠️ |
| Storage `gp2` | 20 | GB | $2.30 |

#### VPC + NAT Gateway — `$32.85/mo`

| Resource | Qty | Unit | Cost |
|---|---|---|---|
| `aws_nat_gateway.this[0]` — NAT hours | 730 | hours | $32.85 |
| Data processed | usage-based | per GB | $0.045/GB |

---

## 🥧 Cost Distribution
```mermaid
pie title Full Infrastructure Cost Distribution — $124.02/mo
    "NAT Gateways (× 2)" : 65.70
    "ALBs (× 2)" : 32.86
    "RDS Primary (db.t4g.micro + storage)" : 13.98
    "EC2 Instances (× 2)" : 9.20
    "RDS DR (storage only — partial)" : 2.30
```

---

## 📋 Resource Inventory
```mermaid
pie title Resource Breakdown — 80 Total
    "Estimated (billable)" : 8
    "Free resources" : 72
```

| Category | Count |
|---|---|
| Total cloud resources detected | **80** |
| Resources with estimated cost | **8** |
| Free resources (SGs, Route Tables, etc.) | **72** |

---

## ⚠️ Known Pricing Gaps

| Issue | Affected Resource | Impact | Notes |
|---|---|---|---|
| `aws_db_instance` price missing | `us-west-2/rds` — `db.t4g.micro` read replica | ~$11.68/mo untracked | Infracost pricing API gap for cross-region read replicas on Graviton. Actual cost mirrors primary instance. |
| Usage-based costs not estimated | NAT Gateway data, ALB LCUs, RDS backup | Variable | Requires `infracost-usage.yml` with traffic estimates to model accurately. |

---

## ▶️ Reproduce This Report
```bash
# From the repo root
infracost breakdown --path ~/finnow-drx-infrastructure/terragrunt

# With usage estimates (optional — improves accuracy of variable costs)
infracost breakdown \
  --path ~/finnow-drx-infrastructure/terragrunt \
  --usage-file infracost-usage.yml

# Export as JSON for CI/CD integration
infracost breakdown \
  --path ~/finnow-drx-infrastructure/terragrunt \
  --format json \
  --out-file infracost-output.json
```

---

<div align="center">

*Generated by [`infracost`](https://www.infracost.io/) · Part of the [FinNow Infrastructure](./README.md) project*

[![Back to README](https://img.shields.io/badge/←%20Back%20to-README-232F3E?style=flat-square&logo=amazon-aws)](./README.md)

</div>
