include "root" { path = find_in_parent_folders("root.hcl") }
terraform { source = "../../_modules/alb" }
dependency "vpc" { config_path = "../vpc" }
dependency "app" { config_path = "../app" }

inputs = {
  name      = "finnow-alb-primary"
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnets   = dependency.vpc.outputs.public_subnets
  target_id = dependency.app.outputs.instance_id
}
