variable "service_name" {
  description = "Base name for SG"
  type        = string
}
variable "container_port" {
  description = "Port to expose for ecs"
  type        = number
}
variable "alb_port" {
  description = "Port to expose for alb"
  type        = number
}
variable "rds_port" {
  description = "Port to expose for rds"
  type        = number
}
variable "redis_port" {
  description = "Port to expose for redis"
  type        = number
  default     = 6379
}
variable "cidr_blocks" {
  description = "Which CIDRs can reach the service"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone to place subnets in (single-AZ simplified setup)"
  type        = string
  default     = ""
}
