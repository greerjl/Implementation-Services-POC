output "cluster_name" {
  description = "ECS cluster name"
  value       = try(aws_ecs_cluster.ecs_cluster.name, "")
}

output "service_name" {
  description = "ECS service name"
  value       = try(aws_ecs_service.ecs_service.name, "")
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = try(aws_ecs_task_definition.ecs_task_definition.arn, "")
}

output "security_group_id" {
  description = "(Optional) Security group ID used by the service (empty if not declared)"
  value       = try(aws_security_group.ecs_security_group.id, "")
}

output "log_group_name" {
  description = "(Optional) CloudWatch log group name (empty if not declared)"
  value       = try(aws_cloudwatch_log_group.cloudwatch_logs_group.name, "")
}