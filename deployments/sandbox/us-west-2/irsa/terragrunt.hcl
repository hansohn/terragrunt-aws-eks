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

# Consume the eks stack's OIDC provider. Mock lets `validate`/`plan` run before
# the eks stack is applied.
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/MOCK0000000000000000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Terraform source block
terraform {
  # Local for_each wrapper around terraform-aws-modules/iam's IRSA submodule.
  source = "${get_repo_root()}/modules//irsa"
}

# Variables utilized by terraform source
inputs = {
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn

  # Trust-only to start. Attach permissions per role via `policies`
  # ("<static-name>" = "<policy-arn>") as each component is deployed.
  roles = {
    ArgoCDrepoRole = {
      namespace_service_accounts = ["argocd:argocd-repo-server"]
    }
    ImageUpdaterRole = {
      namespace_service_accounts = ["argocd:argocd-image-updater"]
    }
    PrometheusRole = {
      namespace_service_accounts = ["prometheus:kube-prometheus-stack-grafana"]
    }
  }
}
