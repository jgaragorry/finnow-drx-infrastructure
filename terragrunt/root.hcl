# ------------------------------------------------------------------------------
# TERRAGRUNT ROOT CONFIGURATION (root.hcl)
# ------------------------------------------------------------------------------

locals {
  # Buscamos el archivo de configuración generado por el bootstrap en la raíz
  backend_vars = read_terragrunt_config(find_in_parent_folders("backend_config.hcl"))
  
  project_name = "finnow-drx"
  owner        = "finops-team"
}

# Configuración del Backend Remoto
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.backend_vars.locals.remote_state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.backend_vars.locals.remote_state_region
    encrypt        = true
    dynamodb_table = local.backend_vars.locals.dynamodb_table
  }
}

# ... (mantén locals y remote_state igual)

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  # Buscamos la región en el path: si el path contiene us-west-2, usa us-west-2
  region = "${contains(split("/", path_relative_to_include()), "us-west-2") ? "us-west-2" : "us-east-1"}"
  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Owner       = "${local.owner}"
      ManagedBy   = "Terragrunt"
      Environment = "Production"
      DR_Strategy = "Warm-Standby"
      Compliance  = "PCI-DSS"
    }
  }
}
EOF
}
