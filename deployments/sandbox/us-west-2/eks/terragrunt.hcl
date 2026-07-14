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

# Consume the sibling vpc deployment's outputs. Mock values let `validate`/`plan`
# run before the vpc stack is applied.
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id          = "vpc-00000000000000000"
    private_subnets = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Local expressions
locals {
  name               = "sandbox-eks"
  kubernetes_version = "1.36"
}

# Terraform source block
terraform {
  # NOTE: verify/bump to the latest 21.x (Renovate tracks this).
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws?version=21.24.0"
}

# Variables utilized by terraform source
inputs = {
  name               = local.name
  kubernetes_version = local.kubernetes_version

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  # Wire the cluster into the vpc stack's private subnets.
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {
    core = {
      # AL2023 is required on EKS 1.34+ (no AL2 AMI is published).
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      min_size     = 1
      max_size     = 2
      desired_size = 1

      labels = {
        role = "core"
      }
    }
  }
}
