# terraform-helloworld

Example Terraform module that generates a random pet name from a greeting.
Used to demonstrate the `terragrunt-aws-template` deployment pattern.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_addressee"></a> [addressee](#input\_addressee) | (Optional) Addressee utilized by random\_pet generator. Defaults to 'Mom'. | `string` | `"Mom"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_random_pet_greeting"></a> [random\_pet\_greeting](#output\_random\_pet\_greeting) | Random Pet Id |
<!-- END_TF_DOCS -->
