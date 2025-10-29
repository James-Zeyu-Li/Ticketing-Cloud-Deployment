# Optional AWS credentials (leave blank when using IAM roles / GitHub OIDC)
variable "aws_access_key_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_session_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "execution_role_arn" {
  type        = string
  description = "IAM role ARN used by ECS tasks to pull images and publish logs"
  default     = "arn:aws:iam::589535382240:role/LabRole"
}

variable "task_role_arn" {
  type        = string
  description = "IAM role ARN assumed by the running task for application permissions"
  default     = "arn:aws:iam::589535382240:role/LabRole"
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to access the services (security group ingress)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_services" {
  description = "Map of application services to deploy via ECS."
  type = map(object({
    repository_name = string
    container_port  = number
    cpu             = string
    memory          = string
    desired_count   = number
    image_tag       = string
  }))

  default = {
    purchase-service = {
      repository_name = "purchase-service"
      container_port  = 8080
      cpu             = "1024"
      memory          = "2048"
      desired_count   = 1
      image_tag       = "latest"
    }
    query-service = {
      repository_name = "query-service"
      container_port  = 8080
      cpu             = "1024"
      memory          = "2048"
      desired_count   = 1
      image_tag       = "latest"
    }
    mq-projection-service = {
      repository_name = "mq-projection-service"
      container_port  = 8080
      cpu             = "512"
      memory          = "1024"
      desired_count   = 1
      image_tag       = "latest"
    }
  }
}

variable "service_image_tags" {
  description = "Override map for image tags (e.g., set via CI to the latest Git SHA)."
  type        = map(string)
  default     = {}
}
