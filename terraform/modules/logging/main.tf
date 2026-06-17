# =============================================================================
# Logging module — Audit & Accountability (AU)
# Implements: AU.L2-3.3.1/3.3.2 (audit logs + traceability), 3.3.8 (protect
#             audit info, S3 Object Lock), 3.3.4 (alert on logging failure)
# Free-Tier: 1 CloudTrail trail (mgmt events) is free; S3/CloudWatch within tiers.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- AU.L2-3.3.8 : Immutable log archive bucket (Object Lock) ----------------
resource "aws_s3_bucket" "log_archive" {
  bucket              = "${var.name_prefix}-logs-${data.aws_caller_identity.current.account_id}"
  object_lock_enabled = true
}

resource "aws_s3_bucket_object_lock_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    default_retention {
      mode = "GOVERNANCE" # use COMPLIANCE for true WORM once validated
      days = 365
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket                  = aws_s3_bucket.log_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid     = "AWSCloudTrailAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [aws_s3_bucket.log_archive.arn]
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.log_archive.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# --- AU.L2-3.3.1 / 3.3.2 : CloudTrail management-event trail ------------------
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "trail_to_cwl" {
  name               = "${var.name_prefix}-trail-cwl"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
}

data "aws_iam_policy_document" "trail_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "trail_to_cwl" {
  name   = "${var.name_prefix}-trail-cwl"
  role   = aws_iam_role.trail_to_cwl.id
  policy = data.aws_iam_policy_document.trail_to_cwl.json
}

data "aws_iam_policy_document" "trail_to_cwl" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.log_archive.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_to_cwl.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true # AU.L2-3.3.8 integrity
  kms_key_id                    = var.kms_key_arn

  depends_on = [aws_s3_bucket_policy.log_archive]
}

# --- AU.L2-3.3.4 : Alert on audit logging process failure --------------------
# Metric filter + alarm: fires if CloudTrail logging is stopped.
resource "aws_cloudwatch_log_metric_filter" "trail_stopped" {
  name           = "${var.name_prefix}-trail-stopped"
  log_group_name = aws_cloudwatch_log_group.trail.name
  pattern        = "{ ($.eventName = StopLogging) || ($.eventName = DeleteTrail) }"
  metric_transformation {
    name      = "CloudTrailStopped"
    namespace = "CMMC/Audit"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "trail_stopped" {
  alarm_name          = "${var.name_prefix}-cloudtrail-stopped"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CloudTrailStopped"
  namespace           = "CMMC/Audit"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "AU.L2-3.3.4: CloudTrail logging was stopped or a trail deleted"
  alarm_actions       = var.alert_sns_topic == "" ? [] : [var.alert_sns_topic]
  treat_missing_data  = "notBreaching"
}

# --- VPC Flow Logs plumbing (consumed by the networking module) --------------
# SI.L2-3.14.6 : monitor inbound/outbound traffic
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/vpc/flowlogs/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "flow_log" {
  name               = "${var.name_prefix}-flowlog"
  assume_role_policy = data.aws_iam_policy_document.flow_assume.json
}

data "aws_iam_policy_document" "flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name   = "${var.name_prefix}-flowlog"
  role   = aws_iam_role.flow_log.id
  policy = data.aws_iam_policy_document.flow_log.json
}

data "aws_iam_policy_document" "flow_log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow.arn}:*"]
  }
}
