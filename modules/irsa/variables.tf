variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider (from the eks stack)."
  type        = string
}

variable "roles" {
  description = <<-EOT
    IRSA roles to create. The map key is the IAM role name. Each role trusts the
    cluster OIDC provider for the listed service-account subjects, given as
    "<namespace>:<service-account>". Attach managed policies via `policies`, a
    map of "<static-name>" = "<policy-arn>".
  EOT
  type = map(object({
    namespace_service_accounts = list(string)
    policies                   = optional(map(string), {})
  }))
  default = {}
}
