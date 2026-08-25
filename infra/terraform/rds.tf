# Security group compartilhado — só os nós do EKS acessam o RDS
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Acesso ao RDS somente via EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
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

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet"
  subnet_ids = module.vpc.private_subnets
  tags       = local.common_tags
}

# Configuração base compartilhada entre as 3 instâncias
locals {
  rds_common = {
    engine                  = "postgres"
    engine_version          = "15"
    instance_class          = "db.t3.micro"
    allocated_storage       = 20
    storage_type            = "gp2"
    username                = "pguser"
    db_subnet_group_name    = aws_db_subnet_group.main.name
    vpc_security_group_ids  = [aws_security_group.rds.id]
    multi_az                = false
    publicly_accessible     = false
    skip_final_snapshot     = true
    deletion_protection     = false
    backup_retention_period = 0
  }
}

# RDS 1 — auth-service
resource "aws_db_instance" "auth" {
  identifier = "${var.project}-auth-pg"
  db_name    = "auth_db"
  password   = random_password.db_password.result

  engine                  = local.rds_common.engine
  engine_version          = local.rds_common.engine_version
  instance_class          = local.rds_common.instance_class
  allocated_storage       = local.rds_common.allocated_storage
  storage_type            = local.rds_common.storage_type
  username                = local.rds_common.username
  db_subnet_group_name    = local.rds_common.db_subnet_group_name
  vpc_security_group_ids  = local.rds_common.vpc_security_group_ids
  multi_az                = local.rds_common.multi_az
  publicly_accessible     = local.rds_common.publicly_accessible
  skip_final_snapshot     = local.rds_common.skip_final_snapshot
  deletion_protection     = local.rds_common.deletion_protection
  backup_retention_period = local.rds_common.backup_retention_period

  tags = merge(local.common_tags, { Service = "auth-service" })
}

# RDS 2 — flag-service
resource "aws_db_instance" "flags" {
  identifier = "${var.project}-flags-pg"
  db_name    = "flags_db"
  password   = random_password.db_password.result

  engine                  = local.rds_common.engine
  engine_version          = local.rds_common.engine_version
  instance_class          = local.rds_common.instance_class
  allocated_storage       = local.rds_common.allocated_storage
  storage_type            = local.rds_common.storage_type
  username                = local.rds_common.username
  db_subnet_group_name    = local.rds_common.db_subnet_group_name
  vpc_security_group_ids  = local.rds_common.vpc_security_group_ids
  multi_az                = local.rds_common.multi_az
  publicly_accessible     = local.rds_common.publicly_accessible
  skip_final_snapshot     = local.rds_common.skip_final_snapshot
  deletion_protection     = local.rds_common.deletion_protection
  backup_retention_period = local.rds_common.backup_retention_period

  tags = merge(local.common_tags, { Service = "flag-service" })
}

# RDS 3 — targeting-service
resource "aws_db_instance" "targeting" {
  identifier = "${var.project}-targeting-pg"
  db_name    = "targeting_db"
  password   = random_password.db_password.result

  engine                  = local.rds_common.engine
  engine_version          = local.rds_common.engine_version
  instance_class          = local.rds_common.instance_class
  allocated_storage       = local.rds_common.allocated_storage
  storage_type            = local.rds_common.storage_type
  username                = local.rds_common.username
  db_subnet_group_name    = local.rds_common.db_subnet_group_name
  vpc_security_group_ids  = local.rds_common.vpc_security_group_ids
  multi_az                = local.rds_common.multi_az
  publicly_accessible     = local.rds_common.publicly_accessible
  skip_final_snapshot     = local.rds_common.skip_final_snapshot
  deletion_protection     = local.rds_common.deletion_protection
  backup_retention_period = local.rds_common.backup_retention_period

  tags = merge(local.common_tags, { Service = "targeting-service" })
}
