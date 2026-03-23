include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/rds"
}

# Comentamos la dependencia para evitar errores de carpeta inexistente
# dependency "vpc" {
#   config_path = "../vpc"
# }

inputs = {
  identifier = "finnow-db-primary"
  is_replica = false
  
  # Valores estáticos (Bypass) para que Terragrunt no falle
  vpc_id     = "vpc-bypass"
  subnet_ids = ["subnet-bypass-1", "subnet-bypass-2"]
}
