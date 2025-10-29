aws_access_key_id     = ""
aws_secret_access_key = ""
aws_session_token     = ""

aws_region         = "us-west-2"
log_retention_days = 3

execution_role_arn = "arn:aws:iam::589535382240:role/LabRole"
task_role_arn      = "arn:aws:iam::589535382240:role/LabRole"

# Restrict access to your IP by setting, e.g.:
# allowed_ingress_cidrs = ["203.0.113.45/32"]
# Default below allows access from anywhere.
allowed_ingress_cidrs = ["0.0.0.0/0"]

app_services = {
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

# GitHub Actions pipeline will override the tags with the Git SHA during deployment.
service_image_tags = {}
