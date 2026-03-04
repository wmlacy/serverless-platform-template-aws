#!/usr/bin/env bash
set -euo pipefail

PROJECT_SLUG="${PROJECT_SLUG:-spt}"
REGION="${REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

BUCKET_NAME="${PROJECT_SLUG}-terraform-state-${ACCOUNT_ID}"
LOCK_TABLE="${PROJECT_SLUG}-terraform-locks"

echo "Bootstrapping Terraform backend..."
echo "  Account:    ${ACCOUNT_ID}"
echo "  Region:     ${REGION}"
echo "  Bucket:     ${BUCKET_NAME}"
echo "  Lock table: ${LOCK_TABLE}"
echo ""

# --- S3 bucket ---
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "S3 bucket already exists: ${BUCKET_NAME}"
else
  echo "Creating S3 bucket: ${BUCKET_NAME}"
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
fi

aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
    }]
  }'

aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- DynamoDB lock table ---
if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "DynamoDB table already exists: ${LOCK_TABLE}"
else
  echo "Creating DynamoDB table: ${LOCK_TABLE}"
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
fi

echo ""
echo "Backend ready. Paste the following into infra/envs/dev/backend.hcl:"
echo ""
echo "bucket         = \"${BUCKET_NAME}\""
echo "key            = \"dev/terraform.tfstate\""
echo "region         = \"${REGION}\""
echo "dynamodb_table = \"${LOCK_TABLE}\""
echo "encrypt        = true"
