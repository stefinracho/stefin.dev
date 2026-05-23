# ==============================================================================
# Global Configuration
# ==============================================================================
variable "aws_region" {
  description = "The AWS region to deploy the bootstrap infrastructure into."
  type        = string
}

variable "project_prefix" {
  description = "A prefix used for naming resources, especially for IAM role restrictions (e.g., my-app)."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Used for tagging."
  type        = string
  default     = "production"
}

# ==============================================================================
# State Backend Configuration
# ==============================================================================
variable "state_bucket_name" {
  description = "The globally unique name for the S3 bucket that will hold Terraform state."
  type        = string
}

# ==============================================================================
# GitHub Actions (OIDC)
# ==============================================================================
variable "github_repo" {
  description = "The GitHub repository in the format org/repo (e.g., YourOrg/YourRepo) to allow OIDC access."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "The github_repo value must be in the format org/repo."
  }
}

variable "github_environment" {
  description = "The GitHub Environment name allowed to assume the deployment role (e.g., production)."
  type        = string
  default     = "production"
}

# ==============================================================================
# Billing & Budgets
# ==============================================================================
variable "budget_limit_amount" {
  description = "The monthly budget limit amount in USD (e.g., 5.00)."
  type        = string
  default     = "5.00"
}

variable "budget_alert_email" {
  description = "The email address to receive budget alerts."
  type        = string
}
