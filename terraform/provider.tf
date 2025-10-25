provider "aws" {
    region = var.aws_region
    default_tags {
        tags = local.default_tags
    }
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # These values will be overridden per-environment during init
    bucket         = "placeholder"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "placeholder"
    encrypt        = true
  }
}
