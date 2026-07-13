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

## :open_book: Usage

Welcome to the terragrunt-aws-eks repo!

Deployments live under `deployments/<namespace>/<account>/<region>/<stack>`, and
that path is how Terragrunt locates each stack. `terragrunt-common.hcl` derives
the namespace, account, region, and stack name from the path, then generates the
S3 backend and AWS provider for each run.

### Stacks

| Path | Source |
| ---- | ------ |
| `deployments/sandbox/us-west-2/vpc` | `tfr://registry.terraform.io/hansohn/vpc/aws` |
| `deployments/sandbox/us-west-2/eks` | `terraform-aws-modules/eks/aws` |

### Authentication & state

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

### Local dev

The `Makefile` runs Terragrunt inside the `hansohn/terraform-aws` container with
your local AWS credentials mounted:

```bash
AWS_PROFILE=sandbox make dev     # drop into the container
# inside the container:
cd deployments/sandbox/us-west-2/vpc
terragrunt plan
```

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[template]: https://github.com/hansohn/terragrunt-aws-template
