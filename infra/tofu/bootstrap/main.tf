# Run ONCE, by hand, before anything in ../environments can run.
#
# It creates the bucket that every other stack keeps its state in - which is why
# it cannot itself use a remote backend. Keep the local state file it produces,
# or accept that re-running it needs an import.

terraform {
  required_version = ">= 1.8"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

resource "aws_s3_bucket" "state" {
  bucket = "kaiju-tofu-state"

  # Losing this bucket means losing the record of every resource built. Making
  # it undeletable by accident is worth the small inconvenience.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
