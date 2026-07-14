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
  aws_region = include.root.locals.aws_region

  name = "hansohn-dev-main"
  cidr = "10.0.0.0/22"
  azs  = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

# Terraform source block
terraform {
  # NOTE: verify/bump to the latest 5.x (Renovate tracks this).
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.13.0"
}

# Variables utilized by terraform source
inputs = {
  name = local.name
  cidr = local.cidr
  azs  = local.azs

  # 10.0.0.0/22 carved into eight /25s: four private + four public.
  private_subnets = ["10.0.0.0/25", "10.0.0.128/25", "10.0.1.0/25", "10.0.1.128/25"]
  public_subnets  = ["10.0.2.0/25", "10.0.2.128/25", "10.0.3.0/25", "10.0.3.128/25"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  # Single NAT gateway shared across AZs (sandbox cost trade-off; not HA).
  enable_nat_gateway = true
  single_nat_gateway = true

  # Subnet tags so EKS / AWS Load Balancer Controller can discover subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
