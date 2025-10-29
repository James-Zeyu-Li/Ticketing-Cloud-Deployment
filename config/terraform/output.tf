output "ecs_cluster_names" {
  description = "Map of service identifiers to the created ECS cluster names."
  value       = { for service, module_data in module.ecs : service => module_data.cluster_name }
}

output "ecs_service_names" {
  description = "Map of service identifiers to the ECS service names."
  value       = { for service, module_data in module.ecs : service => module_data.service_name }
}

output "ecr_repository_urls" {
  description = "Map of service identifiers to their corresponding ECR repository URLs."
  value       = { for service, module_data in module.ecr : service => module_data.repository_url }
}
