output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis cluster port"
  value       = aws_elasticache_cluster.this.port
}

output "redis_sg_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis_sg.id
}