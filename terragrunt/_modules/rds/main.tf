terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# --- VARIABLES ---
variable "identifier" {}
variable "is_replica" { 
  type    = bool
  default = false 
}
variable "replicate_source_db" { 
  type    = string
  default = null 
}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }

# --- SEGURIDAD ---
resource "aws_security_group" "rds" {
  name        = "${var.identifier}-sg-v2"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- RED DE DATOS ---
resource "aws_db_subnet_group" "this" {
  name       = var.identifier 
  subnet_ids = var.subnet_ids
}

# --- INSTANCIA ---
resource "aws_db_instance" "this" {
  identifier            = var.identifier
  engine                = var.is_replica ? null : "postgres"
  engine_version        = var.is_replica ? null : "15"
  instance_class        = "db.t4g.micro"
  allocated_storage     = var.is_replica ? null : 20
  storage_type          = var.is_replica ? null : "gp3"
  skip_final_snapshot   = true
  replicate_source_db   = var.replicate_source_db
  
  db_name               = var.is_replica ? null : "finnowdb"
  username              = var.is_replica ? null : "finadmin"
  password              = var.is_replica ? null : "FinNow2026Secure!" 

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  backup_retention_period = var.is_replica ? 0 : 7 
  parameter_group_name    = "default.postgres15"
}

# --- OUTPUTS ---
output "db_arn" { value = aws_db_instance.this.arn }
output "db_endpoint" { value = aws_db_instance.this.endpoint }
