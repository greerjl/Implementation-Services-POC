bucket         = "prod-terraform-state-datadog-demo-jb"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "prod-terraform-locks"
encrypt        = true