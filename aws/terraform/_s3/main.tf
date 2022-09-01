data "aws_caller_identity" "current" {}

variable "bucket_acl_map" {
  type = map(any)
  default = {
    "mondoo.indellient.logging"        = "log-delivery-write"
    "mondoo.indellient.sample"         = "private"
    "mondoo.indellient.s3-data-events" = "private"
  }
}

variable "s3_data_events_key_prefix" {
  type    = string
  default = "data-events"
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

resource "aws_s3_bucket_policy" "s3_data_events" {
  bucket = aws_s3_bucket.all["mondoo.indellient.s3-data-events"].id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.all["mondoo.indellient.s3-data-events"].arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.all["mondoo.indellient.s3-data-events"].arn}/${var.s3_data_events_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "s3_data_events" {
  name                          = "s3-data-events"
  s3_bucket_name                = aws_s3_bucket.all["mondoo.indellient.s3-data-events"].id
  s3_key_prefix                 = var.s3_data_events_key_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }
}
