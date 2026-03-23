include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/rds"
}

# Accedemos a los datos de la red que ya creamos
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  identifier = "finnow-db-primary"
  is_replica = false
  
  # Inyección dinámica de dependencias
  vpc_id     = dependency.vpc.outputs.vpc_id
  # Usamos las subredes de base de datos (Tier 3)
  subnet_ids = dependency.vpc.outputs.database_subnets
}
