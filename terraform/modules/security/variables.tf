variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "alert_email" {
  description = "Email for security/billing alerts"
  type        = string
}

variable "enable_config" {
  description = "Enable AWS Config (PAID)"
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable GuardDuty (PAID after trial)"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub (PAID after trial)"
  type        = bool
  default     = false
}

variable "enable_billing_alarm" {
  description = "Enable budget/billing alerts (free)"
  type        = bool
  default     = true
}

variable "monthly_budget_usd" {
  description = "Monthly budget threshold in USD"
  type        = number
  default     = 5
}

variable "config_log_bucket" {
  description = "S3 bucket name for AWS Config delivery"
  type        = string
}
