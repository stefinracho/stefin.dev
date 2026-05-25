output "github_actions_plan_role_arn" {
  value       = aws_iam_role.github_actions_plan.arn
  description = "ARN of the IAM role assumed by GitHub Actions for plan operations (PRs and pushes to main). Add this to GitHub Repository Variables as AWS_PLAN_ROLE_ARN."
}

output "github_actions_apply_role_arn" {
  value       = aws_iam_role.github_actions_apply.arn
  description = "ARN of the IAM role assumed by GitHub Actions for apply operations (push to main, gated by the production environment). Add this to GitHub Repository Variables as AWS_APPLY_ROLE_ARN."
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
