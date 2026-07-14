output "role_arns" {
  description = "Map of IRSA role name => IAM role ARN."
  value       = { for name, role in module.iam_role_for_service_accounts : name => role.arn }
}
