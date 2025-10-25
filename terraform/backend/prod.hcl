bucket         = "prod-terraform-state-jayme"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "prod-terraform-locks"
encrypt        = true