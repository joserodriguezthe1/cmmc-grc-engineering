output "enforce_mfa_policy_arn" {
  description = "Attach to human-user groups to require MFA (IA.L2-3.5.3)"
  value       = aws_iam_policy.enforce_mfa.arn
}

output "permission_boundary_arn" {
  description = "Use as permissions boundary on roles/users (AC.L2-3.1.1)"
  value       = aws_iam_policy.permission_boundary.arn
}

output "access_analyzer_arn" {
  description = "IAM Access Analyzer ARN (AC.L2-3.1.5)"
  value       = aws_accessanalyzer_analyzer.this.arn
}
