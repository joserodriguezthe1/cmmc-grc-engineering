output "alert_topic_arn" {
  description = "SNS topic ARN for security and billing alerts"
  value       = aws_sns_topic.alerts.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (empty if disabled)"
  value       = try(aws_guardduty_detector.this[0].id, "")
}
