output "work_queue_url" {
  description = "URL producers send messages to."
  value       = aws_sqs_queue.work.id
}

output "work_queue_arn" {
  description = "ARN of the work queue."
  value       = aws_sqs_queue.work.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.work_dlq.id
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.work_dlq.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster running the workers."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS worker service."
  value       = aws_ecs_service.worker.name
}

output "task_role_arn" {
  description = "IAM role assumed by the running worker container."
  value       = aws_iam_role.task.arn
}

output "kms_key_arn" {
  description = "KMS key used to encrypt the queues and logs."
  value       = aws_kms_key.worker.arn
}
