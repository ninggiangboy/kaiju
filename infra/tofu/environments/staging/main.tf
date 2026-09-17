terraform {
  required_version = ">= 1.8"

  # The state file holds the database password and the SMTP credentials in
  # readable form. It lives in an encrypted remote backend and is NEVER
  # committed - the same rule as every other secret in this project.
  #
  # Chicken and egg: this bucket and lock table must exist before the first run.
  # See ../../bootstrap.
  backend "s3" {
    bucket       = "kaiju-tofu-state"
    key          = "staging/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

module "platform" {
  source = "../../modules/aws"

  name   = "staging"
  domain = var.domain

  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids

  db_instance_class = var.db_instance_class
  db_multi_az       = var.db_multi_az
}

# Outputs are fed into the platform's secret store, never written to a file in
# the repository. `tofu output -json` is the boundary.
output "platform" {
  value     = module.platform
  sensitive = true
}
