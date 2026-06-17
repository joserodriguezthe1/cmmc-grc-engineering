variable "aws_region" {
  description = "AWS region. For real CUI, prefer AWS GovCloud (US)."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address to subscribe to security/billing SNS alerts."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention (keep low to stay in Free Tier)."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Free-Tier cost feature flags. These default OFF because the services they
# enable are NOT in the AWS Free Tier (Config, GuardDuty, Security Hub) or
# only have a limited free trial. Turn on deliberately to capture evidence.
# See docs/architecture/free-tier-cost-notes.md
# ---------------------------------------------------------------------------
variable "enable_config" {
  description = "Enable AWS Config + conformance pack (PAID per config item)."
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable GuardDuty (30-day free trial, then paid)."
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub (30-day free trial, then paid)."
  type        = bool
  default     = false
}

variable "enable_billing_alarm" {
  description = "Create a CloudWatch billing alarm + budget (free; recommended)."
  type        = bool
  default     = true
}

variable "monthly_budget_usd" {
  description = "Budget threshold in USD that triggers an alert."
  type        = number
  default     = 5
}
