# AWS DevOps Agent Terraform Configuration
# This configuration replicates the CDK get-started example setup

provider "awscc" {
  region = var.aws_region
}

provider "aws" {
  region = var.aws_region
}

# Provider alias for the service (secondary) account
# Configure credentials via profile or assume_role
# Example:
#   provider "aws" {
#     alias   = "service"
#     region  = var.aws_region
#     profile = "your-service-account-profile"
#   }
provider "aws" {
  alias  = "service"
  region = var.aws_region
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}
