# =============================================================================
# Storage module — System & Comms Protection (SC) & Media Protection (MP)
# Implements: SC.L2-3.13.10 (key mgmt), 3.13.16 (CUI at rest), MP.L2-3.8.1,
#             AC.L2-3.1.22 (no public CUI)
# Cost note: 1 customer-managed KMS key = ~$1/mo. S3 storage is Free-Tier (5 GB).
# =============================================================================

data "aws_caller_identity" "current" {}

# --- SC.L2-3.13.10 : Customer-managed KMS key for CUI ------------------------
resource "aws_kms_key" "cui" {
  description             = "${var.name_prefix} CUI encryption key (SC.L2-3.13.10)"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "cui" {
  name          = "alias/${var.name_prefix}-cui"
  target_key_id = aws_kms_key.cui.key_id
}

# --- The CUI bucket (encrypted, private, versioned) --------------------------
resource "aws_s3_bucket" "cui" {
  bucket = "${var.name_prefix}-cui-${data.aws_caller_identity.current.account_id}"
}

# SC.L2-3.13.16 / MP.L2-3.8.1 : encryption at rest with the CMK
resource "aws_s3_bucket_server_side_encryption_configuration" "cui" {
  bucket = aws_s3_bucket.cui.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cui.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "cui" {
  bucket = aws_s3_bucket.cui.id
  versioning_configuration {
    status = "Enabled"
  }
}

# AC.L2-3.1.22 : never expose CUI publicly
resource "aws_s3_bucket_public_access_block" "cui" {
  bucket                  = aws_s3_bucket.cui.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SC.L2-3.13.8 : deny non-TLS access (CUI in transit)
resource "aws_s3_bucket_policy" "cui_tls_only" {
  bucket = aws_s3_bucket.cui.id
  policy = data.aws_iam_policy_document.cui_tls_only.json
}

data "aws_iam_policy_document" "cui_tls_only" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.cui.arn, "${aws_s3_bucket.cui.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
