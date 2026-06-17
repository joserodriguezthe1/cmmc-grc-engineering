terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
  }

  # Uncomment after running scripts/bootstrap-backend.sh to create the
  # state bucket + DynamoDB lock table. Local state is fine for first apply.
  # backend "s3" {
  #   bucket         = "REPLACE-cmmc-tfstate"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "cmmc-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CMMC-GRC"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Compliance  = "CMMC-L2"
    }
  }
}
