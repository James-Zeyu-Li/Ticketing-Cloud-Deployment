output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.order_events.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.order_queue.id
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.order_queue.arn
}

output "messaging_policy_arn" {
  description = "ARN of the IAM policy for messaging access"
  value       = aws_iam_policy.messaging_access.arn
}