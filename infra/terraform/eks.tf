module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.project
  cluster_version = "1.36"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Acesso público ao endpoint (kubectl funciona de qualquer lugar)
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    workers = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.eks_node_type]

      min_size     = var.eks_min_nodes
      max_size     = var.eks_max_nodes
      desired_size = var.eks_desired_nodes

      # Disco mínimo para economizar
      disk_size = 20
    }
  }

  tags = local.common_tags
}
