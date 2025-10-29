variable "service_name" {
  description = "Base name for messaging resources"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic"
  type        = string
  default     = "order-processing-events"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "order-processing-queue"
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for SQS queue"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Message retention period for SQS queue"
  type        = number
  default     = 345600  # 4 days
}

variable "receive_wait_time_seconds" {
  description = "Receive wait time for long polling"
  type        = number
  default     = 20
}