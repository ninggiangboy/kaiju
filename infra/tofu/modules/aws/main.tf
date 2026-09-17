# Managed PostgreSQL and object storage for one environment.
#
# This module creates NO Kubernetes object of any kind (CON-76). It builds the
# cluster and the stateful services around it, then stops. Everything that runs
# inside the cluster belongs to Argo CD, and letting both own one object creates
# a sync loop that is very hard to unpick once it is live.

terraform {
  required_version = ">= 1.8"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

data "aws_region" "current" {}

# --- PostgreSQL ------------------------------------------------------------

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "kaiju-${var.name}"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name   = "kaiju-${var.name}-db"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }
}

resource "aws_db_instance" "main" {
  identifier     = "kaiju-${var.name}"
  engine         = "postgres"
  engine_version = "17"

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 4
  storage_encrypted     = true

  db_name  = "kaiju"
  username = "kaiju"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = var.db_multi_az
  publicly_accessible    = false

  backup_retention_period   = 7
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "kaiju-${var.name}-final"

  # Row Level Security is how tenants are isolated (ADR-0012), so the role the
  # application connects as must NOT be able to bypass it. The master user here
  # is for administration; the application's own role is created by migration.
  apply_immediately = false
}

# --- Object storage --------------------------------------------------------

resource "aws_s3_bucket" "attachments" {
  bucket = "kaiju-${var.name}-attachments"
}

resource "aws_s3_bucket_public_access_block" "attachments" {
  bucket                  = aws_s3_bucket.attachments.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_versioning" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  versioning_configuration { status = "Enabled" }
}
