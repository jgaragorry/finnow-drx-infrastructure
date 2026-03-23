include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/app_compute"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  instance_name = "finnow-api-primary" # Nombre real
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_id     = dependency.vpc.outputs.private_subnets[0]
}
