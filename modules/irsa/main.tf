################################################################################
# IRSA - IAM Roles for Service Accounts
#
# terraform-aws-modules/iam's iam-role-for-service-accounts submodule builds a
# single role (trust policy against the cluster OIDC provider + optional managed
# policies). Instantiate it once per entry in var.roles to create several.
################################################################################

module "iam_role_for_service_accounts" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  for_each = var.roles

  name = each.key

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = each.value.namespace_service_accounts
    }
  }

  policies = each.value.policies
}
