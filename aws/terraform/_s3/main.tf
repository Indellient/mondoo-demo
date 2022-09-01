data "aws_caller_identity" "current" {}

variable "bucket_acl_map" {
  type = map(any)
  default = {
    "mondoo.indellient.sample" = "private"
  }
}

resource "aws_s3_bucket" "all" {
  for_each      = var.bucket_acl_map
  bucket        = each.key
  force_destroy = true
  tags = {
    "Mondoo" = "Compliant"
    "Pwd"    = "s3"
  }
}

resource "aws_s3_bucket_acl" "all" {
  for_each = var.bucket_acl_map
  bucket   = each.key
  acl      = each.value
}

resource "aws_s3_account_public_access_block" "enable" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
