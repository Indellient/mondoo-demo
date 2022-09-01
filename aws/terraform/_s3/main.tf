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
    "Mondoo"   = "Non-compliant"
    "TFModule" = "_s3"
  }
}

resource "aws_s3_bucket_acl" "all" {
  for_each = var.bucket_acl_map
  bucket   = each.key
  acl      = each.value
}
