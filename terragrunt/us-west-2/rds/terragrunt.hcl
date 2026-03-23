include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../_modules/rds"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "primary_db" {
  config_path = "../../us-east-1/rds"
}

inputs = {
  identifier          = "finnow-db-replica-sng" # El nombre limpio
  is_replica          = true
  replicate_source_db = dependency.primary_db.outputs.db_arn
  vpc_id              = dependency.vpc.outputs.vpc_id
  subnet_ids          = dependency.vpc.outputs.database_subnets
}
