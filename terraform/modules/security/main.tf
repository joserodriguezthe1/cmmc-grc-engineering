# =============================================================================
# Security module — detection, monitoring, and Free-Tier cost guardrails
# Implements: SI.L2-3.14.3/3.14.6/3.14.7, CA.L2-3.12.1/3.12.3, RA.L2-3.11.2
# Paid services are behind feature flags (default OFF). The billing
# alarm/budget are free and default ON.
# =============================================================================

data "aws_caller_identity" "current" {}

# --- SNS topic for all security + billing alerts -----------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- Cost guardrails (FREE; default ON) --------------------------------------
resource "aws_budgets_budget" "monthly" {
  count        = var.enable_billing_alarm ? 1 : 0
  name         = "${var.name_prefix}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# --- SI.L2-3.14.6 / 3.14.7 : GuardDuty (PAID after 30-day trial) -------------
resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

# --- CA.L2-3.12.1 / SI.L2-3.14.3 : Security Hub (PAID after trial) -----------
resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "nist" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"
  depends_on    = [aws_securityhub_account.this]
}

data "aws_region" "current" {}

# --- CA.L2-3.12.3 / CM.L2-3.4.1 : AWS Config (PAID per config item) ----------
resource "aws_iam_role" "config" {
  count              = var.enable_config ? 1 : 0
  name               = "${var.name_prefix}-config"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
}

data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config[0].arn
  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.name_prefix}-delivery"
  s3_bucket_name = var.config_log_bucket
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}
