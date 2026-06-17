output "kms_key_arn" {
  description = "ARN of the CUI KMS key"
  value       = aws_kms_key.cui.arn
}

output "cui_bucket_name" {
  description = "Name of the CUI S3 bucket"
  value       = aws_s3_bucket.cui.id
}

output "cui_bucket_arn" {
  description = "ARN of the CUI S3 bucket"
  value       = aws_s3_bucket.cui.arn
}
