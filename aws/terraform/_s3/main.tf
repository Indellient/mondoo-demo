variable "bucket_acl_map" {
  type = map(any)
  default = {
    "mondoo.indellient.logging" = "log-delivery-write"
    "mondoo.indellient.sample"  = "private"
  }
}

resource "aws_s3_bucket" "all" {
  for_each            = var.bucket_acl_map
  bucket              = each.key
  object_lock_enabled = true
  force_destroy       = true
  tags = {
    "Mondoo"   = "Compliant"
    "TFModule" = "_s3"
  }
}

resource "aws_s3_bucket_public_access_block" "all" {
  for_each                = var.bucket_acl_map
  bucket                  = each.key
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "all" {
  for_each = var.bucket_acl_map
  bucket   = each.key
  acl      = each.value
}

resource "aws_s3_bucket_versioning" "enabled" {
  for_each = var.bucket_acl_map
  bucket   = each.key
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "enabled" {
  for_each      = var.bucket_acl_map
  bucket        = each.key
  target_bucket = aws_s3_bucket.all["mondoo.indellient.logging"].id
  target_prefix = "log/"
}

resource "aws_kms_key" "s3_encryption" {
  description         = "Used for S3 Bucket encryption configuration"
  enable_key_rotation = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enable" {
  for_each = var.bucket_acl_map
  bucket   = each.key
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_account_public_access_block" "enable" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
