# =============================================================================
# IAM module — Access Control (AC) & Identification and Authentication (IA)
# Implements: AC.L2-3.1.1/3.1.2/3.1.5, IA.L2-3.5.3/3.5.7/3.5.8/3.5.9
# All resources here are in the AWS Always-Free tier.
# =============================================================================

# --- IA.L2-3.5.7 / 3.5.8 / 3.5.9 : Account password policy --------------------
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  max_password_age               = 90
  hard_expiry                    = false
}

# --- IA.L2-3.5.3 : Enforce MFA via an attachable policy ----------------------
# Attach this to your human-user groups. Denies everything except the actions
# needed to enroll an MFA device when the session is not MFA-authenticated.
resource "aws_iam_policy" "enforce_mfa" {
  name        = "${var.name_prefix}-enforce-mfa"
  description = "Deny most actions unless the principal authenticated with MFA (IA.L2-3.5.3)"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "AllowViewAccountInfo"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:ListVirtualMFADevices",
      "iam:GetUser",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
      "iam:DeactivateMFADevice",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }

  statement {
    sid       = "AllowManageOwnPasswordAndKeys"
    effect    = "Allow"
    actions   = ["iam:ChangePassword", "iam:GetLoginProfile"]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid    = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "iam:ChangePassword",
      "iam:GetAccountPasswordPolicy",
      "sts:GetSessionToken",
    ]
    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# --- AC.L2-3.1.5 : Least privilege visibility --------------------------------
# IAM Access Analyzer flags resources shared outside the account/org.
resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "${var.name_prefix}-access-analyzer"
  type          = "ACCOUNT"
}

# --- AC.L2-3.1.1 / 3.1.2 : Example permission boundary -----------------------
# A starting boundary that caps the maximum permissions any role/user can have.
resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.name_prefix}-permission-boundary"
  description = "Maximum-permission boundary (AC.L2-3.1.1/3.1.2). Customize per role."
  policy      = data.aws_iam_policy_document.permission_boundary.json
}

data "aws_iam_policy_document" "permission_boundary" {
  statement {
    sid       = "AllowedServices"
    effect    = "Allow"
    actions   = ["s3:*", "logs:*", "cloudwatch:*", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = ["*"]
  }

  statement {
    sid       = "DenyPrivilegeEscalation"
    effect    = "Deny"
    actions   = ["iam:CreatePolicyVersion", "iam:SetDefaultPolicyVersion", "iam:AttachUserPolicy", "iam:PutUserPolicy"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/${var.name_prefix}-admin"]
    }
  }
}
