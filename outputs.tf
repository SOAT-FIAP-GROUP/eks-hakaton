output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "db_instance_endpoint_produto" {
  value = data.terraform_remote_state.rds.outputs.db_instance_endpoint_produto
}

output "db_instance_endpoint_pedido" {
  value = data.terraform_remote_state.rds.outputs.db_instance_endpoint_pedido
}