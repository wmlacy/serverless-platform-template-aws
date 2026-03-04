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

## Common failure modes

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
