output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# ── RDS — 3 instâncias independentes ──────────────
output "rds_auth_endpoint" {
  description = "Host:porta do RDS para auth-service"
  value       = aws_db_instance.auth.endpoint
}

output "rds_auth_host" {
  value = aws_db_instance.auth.address
}

output "rds_flags_endpoint" {
  description = "Host:porta do RDS para flag-service"
  value       = aws_db_instance.flags.endpoint
}

output "rds_flags_host" {
  value = aws_db_instance.flags.address
}

output "rds_targeting_endpoint" {
  description = "Host:porta do RDS para targeting-service"
  value       = aws_db_instance.targeting.endpoint
}

output "rds_targeting_host" {
  value = aws_db_instance.targeting.address
}

# ── ElastiCache ───────────────────────────────────
output "redis_host" {
  description = "Host do ElastiCache Redis (evaluation-service)"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

# ── Mensageria ───────────────────────────────────
output "sqs_url" {
  description = "URL da fila SQS (evaluation-service produz, analytics-service consome)"
  value       = aws_sqs_queue.events.url
}

output "dynamodb_table" {
  value = aws_dynamodb_table.analytics.name
}

# ── ECR ──────────────────────────────────────────
output "ecr_registry" {
  description = "URL base do ECR para todas as imagens"
  value       = "603727984890.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repositories" {
  description = "URLs dos repositórios ECR criados"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

# ── Helpers ──────────────────────────────────────
output "kubectl_config_cmd" {
  description = "Rode este comando após o apply para configurar o kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "ecr_login_cmd" {
  description = "Login no ECR para push manual de imagens"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin 603727984890.dkr.ecr.${var.aws_region}.amazonaws.com"
}
