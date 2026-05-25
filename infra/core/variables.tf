# ==============================================================================
# Global Configuration
# ==============================================================================
variable "aws_region" {
  description = "The AWS region to deploy the core infrastructure into."
  type        = string
}

variable "project_prefix" {
  description = "A prefix used for naming resources, especially for IAM role restrictions (e.g., my-app)."
  type        = string
  default     = "stefin-dev"
}

variable "environment" {
  description = "Deployment environment. Used for tagging."
  type        = string
  default     = "production"
}
