include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/rds"
}

# Comentamos la dependencia
# dependency "vpc" {
#   config_path = "../vpc"
# }

inputs = {
  identifier = "finnow-db-replica"
  is_replica = true
  
  # Valores estáticos (Bypass)
  vpc_id     = "vpc-bypass"
  subnet_ids = ["subnet-bypass-1", "subnet-bypass-2"]
}
