output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_autoscaling_role_arn" {
  description = "ARN of the ECS autoscaling role"
  value       = aws_iam_role.ecs_autoscaling_role.arn
}

output "secrets_kms_key_id" {
  description = "ID of the KMS key for secrets"
  value       = aws_kms_key.secrets.id
}

output "secrets_kms_key_arn" {
  description = "ARN of the KMS key for secrets"
  value       = aws_kms_key.secrets.arn
}

output "logs_kms_key_id" {
  description = "ID of the KMS key for logs"
  value       = aws_kms_key.logs.id
}

output "logs_kms_key_arn" {
  description = "ARN of the KMS key for logs"
  value       = aws_kms_key.logs.arn
}