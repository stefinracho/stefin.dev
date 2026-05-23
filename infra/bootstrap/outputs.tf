output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the IAM role assumed by GitHub Actions via OIDC. Add this to GitHub Repository Secrets."
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN of the GitHub OIDC identity provider."
}

output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket holding Terraform remote state."
}

output "state_bucket_region" {
  value       = var.aws_region
  description = "AWS region in which the Terraform state bucket lives."
}
