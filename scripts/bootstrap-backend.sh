#!/usr/bin/env bash
# One-time bootstrap of a remote Terraform state backend:
#   - S3 bucket (versioned, encrypted, public access blocked) for state
#   - DynamoDB table for state locking
# All Free-Tier eligible. After running, uncomment the backend block in
# terraform/environments/dev/providers.tf and run `terraform init -migrate-state`.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="cmmc-tfstate-${ACCOUNT_ID}"
TABLE="cmmc-tflock"

echo "Region:  ${REGION}"
echo "Bucket:  ${BUCKET}"
echo "Table:   ${TABLE}"

# --- S3 state bucket ---
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "Bucket already exists."
else
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
fi

aws s3api put-bucket-versioning --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "${BUCKET}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block --bucket "${BUCKET}" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- DynamoDB lock table ---
if aws dynamodb describe-table --table-name "${TABLE}" >/dev/null 2>&1; then
  echo "Lock table already exists."
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
fi

echo ""
echo "Backend ready. Now edit terraform/environments/dev/providers.tf:"
echo "  bucket         = \"${BUCKET}\""
echo "  dynamodb_table = \"${TABLE}\""
echo "Then run: cd terraform/environments/dev && terraform init -migrate-state"
