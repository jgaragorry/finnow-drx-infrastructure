include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/vpc"
}

inputs = {
  vpc_name = "finnow-vpc-dr"
  cidr     = "10.1.0.0/16" # Diferente CIDR para DR
  azs      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnets   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets  = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
  database_subnets = ["10.1.20.0/24", "10.1.21.0/24", "10.1.22.0/24"]

  single_nat_gateway = true
}
