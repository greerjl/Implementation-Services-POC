### Terraform main configuration file ###

# Local variables
locals {
  ssm_config_full_path  = "/app/${var.env}/config"
  ssm_api_key_full_path = "/app/${var.env}/api_key"
  default_tags = {
    Project     = var.name
    Environment = var.env
  }
}

## Terraform data sources for AWS
data "aws_caller_identity" "this" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

## Terraform resources for AWS

resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE"
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

resource "aws_iam_role" "iam_role_ecs_task_execution" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
  name = "${var.name}-ecs-task-execution-role"
}

resource "aws_iam_role_policy" "ssm_read_parameters_policy" {
  name = "ssm-read-parameters-policy"
  role = aws_iam_role.iam_role_ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.this.account_id}:parameter${aws_ssm_parameter.ssm_config.name}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.this.account_id}:parameter${aws_ssm_parameter.ssm_api_key.name}"
        ]
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.iam_role_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "cloudwatch_logs_group" {
  name              = "/ecs/${var.name}-${var.env}-logs"
  retention_in_days = 7
}

resource "aws_ssm_parameter" "ssm_api_key" {
  name      = "/app/${var.env}/api_key"
  type      = "SecureString"
  value     = "PLACEHOLDER_API_KEY"
  overwrite = true
  tags      = local.default_tags
}

resource "aws_ssm_parameter" "ssm_config" {
  name      = "/app/${var.env}/config"
  type      = "String"
  value     = "{\"APP_NAME\":\"demo-app\",\"ENV\":\"dev\",\"DEBUG\":\"true\"}"
  overwrite = true
  tags      = local.default_tags
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name}-${var.env}-cluster"
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.name}-${var.env}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.iam_role_ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "${var.name}-container"
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cloudwatch_logs_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.name}"
        }
      }
      environment = [
        {
          name  = var.name
          value = var.env
          debug = var.env == "dev" ? "true" : "false"
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.this.account_id}:parameter${aws_ssm_parameter.ssm_api_key.name}"
        },
        {
          name      = "APP_CONFIG_JSON"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.this.account_id}:parameter${aws_ssm_parameter.ssm_config.name}"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_security_group" "ecs_security_group" {
  name        = "${var.name}-${var.env}-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.name}-${var.env}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_security_group.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy_attachment
  ]
}