terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # NOTE: When running the initial bootstrap locally, comment out this 
  # `backend "s3"` block. After the S3 bucket is created, uncomment
  # this block and run `terraform init -backend-config="config.s3.tfbackend"`
  # to migrate the state to the remote backend.
  backend "s3" {
    bucket       = ""
    region       = ""
    key          = "global/s3/terraform.tfstate"
    use_lockfile = true
  }
}

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
