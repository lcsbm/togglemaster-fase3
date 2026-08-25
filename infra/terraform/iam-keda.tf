# ── IRSA para o KEDA ler a profundidade da fila SQS ──────────────────────────
module "keda_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.project}-keda-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["keda:keda-operator"]
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role_policy" "keda_sqs" {
  name = "${var.project}-keda-sqs-policy"
  role = module.keda_irsa.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
      Resource = aws_sqs_queue.events.arn
    }]
  })
}

# ── Permissões SQS + DynamoDB + ECR para os pods da aplicação ────────────────
# Os nós do EKS herdam esta policy — evaluation e analytics acessam AWS
# sem precisar de AWS_ACCESS_KEY_ID/SECRET no cluster (instance profile).
resource "aws_iam_role_policy" "node_aws_services" {
  name = "${var.project}-node-aws-policy"
  role = module.eks.eks_managed_node_groups["workers"].iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.analytics.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [for repo in aws_ecr_repository.services : repo.arn]
      }
    ]
  })
}

output "keda_role_arn" {
  description = "ARN da role IRSA anotada no SA do KEDA via Helm"
  value       = module.keda_irsa.iam_role_arn
}
