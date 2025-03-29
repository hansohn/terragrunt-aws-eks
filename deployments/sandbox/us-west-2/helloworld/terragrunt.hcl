# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include all settings from the root terragrunt-common.hcl file
include "root" {
  path   = find_in_parent_folders("terragrunt-common.hcl")
  expose = true
}

# Local expressions
locals {
  parent_dir          = get_parent_terragrunt_dir("terragrunt-common.hcl")
  aws_account_id      = include.root.locals.aws_account_id
  aws_account_name    = include.root.locals.aws_account_name
  aws_region          = include.root.locals.aws_region
  titled_account_name = join("", [for i in split("-", local.aws_account_name) : title(i)])
}

# Terraform source block
terraform {
  source = "${local.parent_dir}//modules/terraform-helloworld"
}

# Variables utilized by terraform source
inputs = {
  addressee = "Bob"
}
