# Core Infrastructure

This directory contains the Terraform configuration for the core networking (VPC) and compute (EC2/Traefik) resources.

## Required GitHub Secrets/Variables

To deploy this directory via GitHub Actions, the following **Repository Variables** must be set:
* `AWS_REGION`: The AWS region to deploy to.
* `STATE_BUCKET_NAME`: The name of the S3 bucket storing the Terraform state.
* `ACME_EMAIL`: The email address used by Traefik to register Let's Encrypt certificates.
