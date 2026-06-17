# =============================================================================
# CMMC L2 baseline — dev environment
# Wires together the security-control modules. Each module is annotated with
# the CMMC practices it implements.
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "cmmc-${var.environment}"
}

# --- Identity & Access (AC, IA) ---------------------------------------------
module "iam" {
  source      = "../../modules/iam"
  name_prefix = local.name_prefix
}

# --- Data protection: KMS + CUI bucket (SC, MP) -----------------------------
module "storage" {
  source      = "../../modules/storage"
  name_prefix = local.name_prefix
}

# --- Audit & Accountability: CloudTrail + log archive (AU) -------------------
module "logging" {
  source             = "../../modules/logging"
  name_prefix        = local.name_prefix
  kms_key_arn        = module.storage.kms_key_arn
  log_retention_days = var.log_retention_days
  alert_sns_topic    = module.security.alert_topic_arn
}

# --- Detection, monitoring, cost guardrails (SI, CA, RA) ---------------------
module "security" {
  source               = "../../modules/security"
  name_prefix          = local.name_prefix
  alert_email          = var.alert_email
  enable_config        = var.enable_config
  enable_guardduty     = var.enable_guardduty
  enable_security_hub  = var.enable_security_hub
  enable_billing_alarm = var.enable_billing_alarm
  monthly_budget_usd   = var.monthly_budget_usd
  config_log_bucket    = module.logging.log_archive_bucket
}

# --- Network boundary (SC) ---------------------------------------------------
module "networking" {
  source              = "../../modules/networking"
  name_prefix         = local.name_prefix
  region              = var.aws_region
  log_destination_arn = module.logging.flow_log_group_arn
  flow_log_role_arn   = module.logging.flow_log_role_arn
}
