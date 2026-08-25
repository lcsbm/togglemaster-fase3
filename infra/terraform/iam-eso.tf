# ── IRSA para o ESO acessar o Secrets Manager ────────────────────────────────
module "eso_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.project}-eso-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role_policy" "eso_secrets_manager" {
  name = "${var.project}-eso-sm-policy"
  role = module.eso_irsa.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:603727984890:secret:${var.project}/*"
    }]
  })
}

# ── Segredos no AWS Secrets Manager ──────────────────────────────────────────
# Os valores chegam via variáveis de ambiente (TF_VAR_*) e ficam APENAS no SM.
# O ESO cria os K8s Secrets lendo daqui — nenhum segredo entra no tfstate do K8s.

resource "aws_secretsmanager_secret" "auth" {
  name                    = "${var.project}/auth-service"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "auth" {
  secret_id = aws_secretsmanager_secret.auth.id
  secret_string = jsonencode({
    DATABASE_URL = "postgres://pguser:${random_password.db_password.result}@${aws_db_instance.auth.address}:5432/auth_db?sslmode=require"
    MASTER_KEY   = random_password.master_key.result
  })
}

resource "aws_secretsmanager_secret" "flags" {
  name                    = "${var.project}/flag-service"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "flags" {
  secret_id = aws_secretsmanager_secret.flags.id
  secret_string = jsonencode({
    DATABASE_URL    = "postgresql://pguser:${random_password.db_password.result}@${aws_db_instance.flags.address}:5432/flags_db?sslmode=require"
    SERVICE_API_KEY = random_password.service_api_key.result
  })
}

resource "aws_secretsmanager_secret" "targeting" {
  name                    = "${var.project}/targeting-service"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "targeting" {
  secret_id = aws_secretsmanager_secret.targeting.id
  secret_string = jsonencode({
    DATABASE_URL    = "postgresql://pguser:${random_password.db_password.result}@${aws_db_instance.targeting.address}:5432/targeting_db?sslmode=require"
    SERVICE_API_KEY = random_password.service_api_key.result
  })
}

resource "aws_secretsmanager_secret" "evaluation" {
  name                    = "${var.project}/evaluation-service"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "evaluation" {
  secret_id = aws_secretsmanager_secret.evaluation.id
  secret_string = jsonencode({
    REDIS_URL       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
    SERVICE_API_KEY = random_password.service_api_key.result
    AWS_SQS_URL     = aws_sqs_queue.events.url
  })
}

resource "aws_secretsmanager_secret" "analytics" {
  name                    = "${var.project}/analytics-service"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "analytics" {
  secret_id = aws_secretsmanager_secret.analytics.id
  secret_string = jsonencode({
    AWS_SQS_URL = aws_sqs_queue.events.url
  })
}

output "eso_role_arn" {
  value = module.eso_irsa.iam_role_arn
}
