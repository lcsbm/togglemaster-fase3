variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto (usado como prefixo dos recursos)"
  type        = string
  default     = "togglemaster"
}

variable "eks_node_type" {
  description = "Tipo de instância EC2 para os nós do EKS"
  type        = string
  default     = "t3.medium"
}

variable "eks_desired_nodes" {
  type    = number
  default = 2
}

variable "eks_min_nodes" {
  type    = number
  default = 1
}

variable "eks_max_nodes" {
  type    = number
  default = 3
}

variable "eks_public_access_cidrs" {
  description = "CIDRs autorizados a acessar o endpoint público do EKS (kubectl)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_admin_iam_arn" {
  description = "ARN do IAM user/role que terá acesso admin ao cluster EKS via kubectl"
  type        = string
  default     = "arn:aws:iam::603727984890:user/togglemaster-ci"
}

variable "github_repo" {
  description = "Repositório GitHub no formato org/repo (usado pelo ArgoCD)"
  type        = string
  default     = "lcsbm/togglemaster-fase3"
}
