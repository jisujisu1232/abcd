locals {
  log_bucket = length(var.log_bucket_name)==0 ? "${var.product_name}-${var.stage}-vpc-flow-logs" :  var.log_bucket_name
  log_prefix = "Flow-Logs"
  log_expiration_days = "${floor((var.log_expiration_days < 90 ? 90 : var.log_expiration_days) / 3)}"
}

resource "aws_flow_log" "example" {
  log_destination      = "${aws_s3_bucket.this.arn}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = "${aws_vpc.this.id}"
}


resource "aws_s3_bucket" "this" {
  bucket        = "${local.log_bucket}"
  acl    = "private"

  lifecycle_rule {
    id      = "${local.log_bucket}/${local.log_prefix}/"
    enabled = true

    prefix = "${local.log_prefix}/"

    tags = {
      "rule"      = "log"
      "autoclean" = "true"
    }

    transition {
      days          = "${local.log_expiration_days}"
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = "${local.log_expiration_days*2}"
      storage_class = "GLACIER"
    }

    expiration {
      days = "${local.log_expiration_days*3}"
    }
  }
  force_destroy = true
}
