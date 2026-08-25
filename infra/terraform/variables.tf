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

variable "github_repo" {
  description = "Repositório GitHub no formato org/repo (usado pelo ArgoCD)"
  type        = string
  default     = "lcsbm/togglemaster-fase3"
}
