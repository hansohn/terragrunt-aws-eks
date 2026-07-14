<div align="center">
  <h3>terragrunt-aws-eks</h3>
  <p>Terragrunt AWS EKS Deployments</p>
  <p>
    <!-- Build Status -->
    <a href="https://actions-badge.atrox.dev/hansohn/terragrunt-aws-eks/goto?ref=main">
      <img src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fhansohn%2Fterragrunt-aws-eks%2Fbadge%3Fref%3Dmain&style=for-the-badge">
    </a>
    <!-- Github Tag -->
    <a href="https://gitHub.com/hansohn/terragrunt-aws-eks/tags/">
      <img src="https://img.shields.io/github/tag/hansohn/terragrunt-aws-eks.svg?style=for-the-badge">
    </a>
    <!-- License -->
    <a href="https://github.com/hansohn/terragrunt-aws-eks/blob/main/LICENSE">
      <img src="https://img.shields.io/github/license/hansohn/terragrunt-aws-eks.svg?style=for-the-badge">
    </a>
  </p>
</div>

## :open_book: Overview

`terragrunt-aws-eks` stands up an Amazon EKS platform on AWS with
[Terragrunt](https://terragrunt.gruntwork.io/). It is composed of small,
single-purpose **stacks** — the network, the cluster, and workload IAM — that
each source a community Terraform module and are wired together with Terragrunt
dependencies. Applied in order, they take an environment from an empty account to
a running EKS cluster with IRSA roles ready for platform components.

Everything is convention-driven: deployments live under
`deployments/<namespace>/<account>/<region>/<stack>`, and that path is how
Terragrunt locates each stack. `terragrunt-common.hcl` derives the namespace,
account, region, and stack name from the path, then generates the S3 backend and
AWS provider for every run.

## Stacks

Applied in dependency order — each consumes the previous stack's outputs:

| Stack | Path | Module | Purpose |
| ----- | ---- | ------ | ------- |
| `vpc` | `deployments/sandbox/us-west-2/vpc` | `terraform-aws-modules/vpc/aws` | VPC with public/private subnets and a single NAT gateway |
| `eks` | `deployments/sandbox/us-west-2/eks` | `terraform-aws-modules/eks/aws` (v21) | EKS cluster — Kubernetes 1.36 on AL2023 nodes — in the VPC's private subnets |
| `irsa` | `deployments/sandbox/us-west-2/irsa` | `terraform-aws-modules/iam` (via `modules/irsa`) | IAM Roles for Service Accounts that trust the cluster OIDC provider |

The dependency chain is `vpc → eks → irsa`: the `eks` stack reads `vpc_id` /
`private_subnets` from `vpc`, and the `irsa` stack reads the cluster
`oidc_provider_arn` from `eks` — both through Terragrunt `dependency` blocks
(with `mock_outputs` so `plan`/`validate` run before upstreams are applied).

### Local modules

- **`modules/irsa`** — a thin `for_each` wrapper around
  `terraform-aws-modules/iam//modules/iam-role-for-service-accounts` (that
  submodule builds one role per call), letting the `irsa` stack declare several
  roles from a single deployment.

## Authentication & state

`terragrunt-common.hcl` resolves the target account ID with
`scripts/get-aws-account-id` (`aws sts get-caller-identity`) and assumes
`Org/CodeDeployRole` in that account for both the backend and the AWS provider.
State is stored per-account in the S3 bucket `<account>-tf-state-<region>`, with
locking via the `terraform-state-lock` DynamoDB table.

> **Migration note:** this repo is being aligned to the
> [`terragrunt-aws-template`][template] auth model — identity from
> `aws sts get-caller-identity`, the backend bucket from an SSM parameter,
> S3-native locking, and no `assume_role`. That change is tracked separately and
> depends on the target account being bootstrapped.

## Local dev

The `Makefile` runs Terragrunt inside the `hansohn/terraform-aws` container with
your local AWS credentials mounted:

```bash
AWS_PROFILE=sandbox make dev     # drop into the container
# inside the container, from a stack directory:
cd deployments/sandbox/us-west-2/vpc
terragrunt plan
```

## CI

GitHub Actions (`.github/workflows/terragrunt.yml`) checks HCL formatting
(`terragrunt hcl format`) and lints Terraform (`tflint`) on every push.

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[template]: https://github.com/hansohn/terragrunt-aws-template
