output "cui_bucket_name" {
  description = "Name of the encrypted CUI S3 bucket"
  value       = module.storage.cui_bucket_name
}

output "kms_key_arn" {
  description = "ARN of the CMMC KMS key (CUI encryption)"
  value       = module.storage.kms_key_arn
}

output "log_archive_bucket" {
  description = "Immutable (Object Lock) audit log archive bucket"
  value       = module.logging.log_archive_bucket
}

output "cloudtrail_name" {
  description = "Name of the management-event CloudTrail"
  value       = module.logging.cloudtrail_name
}

output "alert_topic_arn" {
  description = "SNS topic for security & billing alerts"
  value       = module.security.alert_topic_arn
}

output "vpc_id" {
  description = "VPC ID for the CUI enclave"
  value       = module.networking.vpc_id
}
