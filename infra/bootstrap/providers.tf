provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_prefix
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "bootstrap"
      Repository  = var.github_repo
    }
  }
}
