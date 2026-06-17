variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region (for AZ and endpoint service names)"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "flow_log_role_arn" {
  description = "IAM role ARN for VPC flow log delivery"
  type        = string
}

variable "log_destination_arn" {
  description = "CloudWatch log group ARN for flow logs"
  type        = string
}
