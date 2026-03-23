# Hereda la configuración del backend del archivo raíz
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Apunta al código del módulo local
terraform {
  source = "../../_modules/vpc"
}

# Parámetros específicos para la Región Primaria (Virginia)
inputs = {
  vpc_name = "finnow-vpc-primary"
  cidr     = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  # Para el laboratorio: un solo NAT Gateway ahorra mucho dinero
  single_nat_gateway = true 
}
