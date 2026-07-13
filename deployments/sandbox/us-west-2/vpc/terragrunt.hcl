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
  source = "tfr://registry.terraform.io/hansohn/vpc/aws?version=1.0.3"
}

# Variables utilized by terraform source
inputs = {
  region             = local.aws_region
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
  
  namespace = "hansohn"
  stage     = "dev"
  name      = "main"
  
  cidr_block                       = "10.0.0.0/22"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  enable_internet_gateway          = true
  
  enable_dynamic_subnets   = true
  enable_public_network    = true
  enable_protected_network = true
  enable_private_network   = true
  
  default_network_acl_ingress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  
  public_ingress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  public_egress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  
  protected_ingress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  protected_egress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  
  private_ingress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  private_egress_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 101
      rule_action     = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}
