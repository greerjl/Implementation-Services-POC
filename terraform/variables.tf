variable "env" {
  description = "Environment name (e.g., dev or prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "image" {
  description = "Full image name including registry and tag"
  type        = string
  default     = "dummy" # placeholder; will be overridden in tfvars
}

variable "name" {
  description = "Base app name"
  type        = string
  default     = "app-demo"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "app-demo"
}

variable "ssm_config_path" {
  description = "Path to the SSM parameter for app config"
  type        = string
  default     = "/app/config" # static default; we'll make it dynamic later
}

variable "ssm_api_key_path" {
  description = "Path to the SSM parameter for the API key"
  type        = string
  default     = "/app/api_key"
}
