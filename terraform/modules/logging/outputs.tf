output "log_archive_bucket" {
  description = "Immutable audit log archive bucket name"
  value       = aws_s3_bucket.log_archive.id
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = aws_cloudtrail.main.name
}

output "flow_log_group_arn" {
  description = "CloudWatch log group ARN for VPC flow logs"
  value       = aws_cloudwatch_log_group.flow.arn
}

output "flow_log_role_arn" {
  description = "IAM role ARN for VPC flow log delivery"
  value       = aws_iam_role.flow_log.arn
}
