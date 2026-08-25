resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg"
  description = "Acesso ao Redis somente via EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-cache-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  tags = local.common_tags
}
