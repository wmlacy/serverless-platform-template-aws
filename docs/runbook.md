# Runbook

## 1. Bootstrap the Terraform backend

Run once per AWS account. Creates the S3 state bucket and DynamoDB lock table.

```bash
cd scripts
bash bootstrap_backend.sh
```

Copy the printed output into `infra/envs/dev/backend.hcl` (gitignored).

## 2. Set your email (gitignored)

Create `infra/envs/dev/dev.auto.tfvars` (gitignored — never commit this):

```hcl
budget_alert_email = "your-email@example.com"
```

## 3. Deploy

```bash
cd infra/envs/dev
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
```

The API base URL is printed as the `api_base_url` output.

## 4. Run the smoke test

```bash
# Auto-fetches API URL from Terraform output
bash scripts/smoke_test.sh

# Or pass the URL explicitly
bash scripts/smoke_test.sh https://abc123.execute-api.us-east-1.amazonaws.com
```

## 5. Run unit tests

```bash
cd services/api
pip install -r requirements-dev.txt
pytest tests/
```

## 6. Destroy

```bash
cd infra/envs/dev
terraform destroy
```

This does **not** delete the S3 state bucket or DynamoDB lock table (bootstrap resources). Remove those manually if no longer needed.

## Common errors and fixes

### 401 Unauthorized
Cognito is enabled and the request is missing or has an expired JWT.
- Check `enable_cognito` in your tfvars.
- Get a fresh token: see [docs/cognito.md](cognito.md).
- Pass the token as `Authorization: <token>` (no "Bearer" prefix for Cognito HTTP API).

### 403 Forbidden
JWT is present but invalid — wrong audience, issuer, or user pool.
- Confirm `cognito_client_id` and `cognito_issuer_url` match Terraform outputs.
- Re-fetch the token for the correct client ID.

### 500 Internal Server Error
Lambda threw an unhandled exception. Check the logs:
```bash
aws logs tail /aws/lambda/spt-dev-api --follow --region us-east-1
```
Common causes: `TABLE_NAME` env var missing, IAM permission denied on DynamoDB.

### DynamoDB AccessDeniedException
The Lambda IAM role is missing a required permission.
- Verify `modules/iam/main.tf` includes `dynamodb:GetItem` and `dynamodb:PutItem`.
- Verify the `Resource` ARN matches the actual table ARN (`terraform output table_name`).
- Re-apply Terraform after any IAM change.

### Missing TABLE_NAME environment variable
Lambda logs show `KeyError: 'TABLE_NAME'`.
- Check `modules/lambda_api/main.tf` — the `TABLE_NAME` env var must be set.
- Re-apply Terraform.

### How to check CloudWatch logs
```bash
# Lambda logs (live tail)
aws logs tail /aws/lambda/spt-dev-api --follow --region us-east-1

# API Gateway access logs
aws logs tail /aws/apigateway/spt-dev-api --follow --region us-east-1
```

### How to rerun the smoke test
```bash
bash scripts/smoke_test.sh
# or with an explicit URL:
bash scripts/smoke_test.sh https://abc123.execute-api.us-east-1.amazonaws.com
```

## Terraform failure modes

### `Error: NoCredentialsError`
Your AWS credentials are not configured. Run `aws configure` or export `AWS_PROFILE`.

### `Error: Backend initialization required`
You are missing `backend.hcl`. Copy `backend.hcl.example`, fill in the values, and re-run `terraform init -backend-config=backend.hcl`.

### `Error: BucketAlreadyOwnedByYou`
The bootstrap script tried to create a bucket that already exists in your account. This is safe to ignore — the script continues.

### Lambda zip not found during plan
The `archive_file` data source zips `services/api/src/` at plan time. Ensure the path exists and `handler.py` is present.

### `Error: InvalidClientTokenId` (budget module)
Budget alerts require the account to have billing alerts enabled. Go to AWS Billing > Billing Preferences and enable "Receive Billing Alerts".
