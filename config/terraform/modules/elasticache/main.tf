# Single Redis instance for simplicity

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-cache-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "redis_sg" {
  name   = "${var.name}-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.ecs_security_group_ids
    description     = "ECS tasks to Redis"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-redis-sg" }
}

resource "random_password" "auth" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?:"
}

# Single Redis cache cluster (simpler than replication group)
resource "aws_elasticache_cluster" "this" {
  cluster_id      = "${var.name}-redis"
  engine          = "redis"
  engine_version  = var.engine_version
  node_type       = var.node_type
  port            = var.port
  num_cache_nodes = 1

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis_sg.id]

  # Security
  parameter_group_name     = "default.redis7"
  snapshot_retention_limit = var.snapshot_retention_limit

  tags = {
    Name        = "${var.name}-redis"
    Environment = "aws"
    Service     = var.name
  }
}