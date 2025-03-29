locals {
  # Determine deployment location based on the repo path:
  #   "<namespace>/<aws_account_name>/<aws_region>/<deployment_name>"

  relative_path     = path_relative_to_include()
  relative_path_lst = split("/", local.relative_path)

  namespace        = element(local.relative_path_lst, 0)
  aws_account_name = element(local.relative_path_lst, 1)
  aws_region_raw   = element(local.relative_path_lst, 2)
  deployment_name  = element(local.relative_path_lst, 3)

  aws_account_id     = run_cmd("--terragrunt-quiet", "/app/scripts/get-aws-account-id", local.aws_account_name)
  aws_region         = length(regexall("^([a-z]{2}(?:-gov){0,1}-(?:central|east|north|south|west){1,2}-\\d)$", local.aws_region_raw)) > 0 ? local.aws_region_raw : local.default_aws_region
  default_aws_region = get_env("AWS_DEFAULT_REGION", "us-west-2")
  repo_name          = get_env("REPO_NAME", "unknown")

  config = {
    deployments = {
      bucket     = "${local.aws_account_name}-tf-state-${local.aws_region}"
      lock_table = "terraform-state-lock"
      role_name  = "Org/CodeDeployRole"
    }
  }

  lock_table   = local.config[local.namespace]["lock_table"]
  state_bucket = local.config[local.namespace]["bucket"]
  role_name    = local.config[local.namespace]["role_name"]
}

generate "backend" {
  path      = "auto-backend.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    terraform {
      backend "s3" {
        bucket         = "${local.state_bucket}"
        key            = "${local.repo_name}/${local.relative_path}/terraform.tfstate"
        region         = "us-west-2"
        dynamodb_table = "${local.lock_table}"
        encrypt        = true
        assume_role = {
          role_arn = "arn:aws:iam::${local.aws_account_id}:role/${local.role_name}"
        }
      }
    }
  EOF
}

generate "provider" {
  path      = "auto-provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<-EOF
    # local.aws_account_name: ${local.aws_account_name}
    # local.aws_account_id: ${local.aws_account_id}
    # local.aws_region: ${local.aws_region}
    # local.deployment_name: ${local.deployment_name}

    provider "aws" {
      region = "${local.aws_region}"

      assume_role {
        role_arn = "arn:aws:iam::${local.aws_account_id}:role/${local.role_name}"
      }

      default_tags {
        tags = {
          "Repo"            = "${local.repo_name}"
          "terraform:state" = "s3://${local.state_bucket}/${local.repo_name}/${local.relative_path}/terraform.tfstate"
        }
      }
    }
  EOF
}

terraform {
  extra_arguments "output" {
    commands  = ["plan"]
    arguments = ["-out", "terraform.plan"]
  }
}
