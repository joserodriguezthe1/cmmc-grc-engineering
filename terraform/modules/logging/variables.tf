variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt logs"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

variable "alert_sns_topic" {
  description = "SNS topic ARN for logging-failure alerts (empty to skip)"
  type        = string
  default     = ""
}
