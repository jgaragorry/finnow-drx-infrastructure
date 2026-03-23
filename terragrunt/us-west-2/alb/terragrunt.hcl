include "root" { path = find_in_parent_folders("root.hcl") }
terraform { source = "../../_modules/alb" }
# dependency "vpc" { config_path = "../vpc" }
# dependency "app" { config_path = "../app" }

inputs = {
  name      = "finnow-alb-dr"
  vpc_id    = "vpc-bypass"
  subnets   = ["subnet-bypass"]
  target_id = "i-bypass"
}
