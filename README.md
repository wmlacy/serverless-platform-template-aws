# Serverless Platform Template (AWS)

A minimal, production-shaped serverless API on AWS using Terraform and Python 3.12. Designed to stay under $5/month at low traffic when deployed with the included guardrails.

## What it is

- **API Gateway HTTP API** — routes: `GET /health`, `POST /items`, `GET /items/{id}`
- **Lambda** — Python 3.12, 128 MB, 10s timeout
- **DynamoDB** — on-demand billing, SSE enabled
- **CloudWatch** — log retention 14 days, Lambda errors alarm, API GW 5XX + latency alarms
- **Budgets** — $5/month alert (set your email before apply)
- **Cognito** (optional) — JWT auth toggle via `var.enable_cognito`

## Quick start

### 1. Bootstrap the backend

```bash
bash scripts/bootstrap_backend.sh
# Copy the printed values into infra/envs/dev/backend.hcl
```

### 2. Set your email (gitignored)

```bash
cat > infra/envs/dev/dev.auto.tfvars <<EOF
budget_alert_email = "your-email@example.com"
EOF
```

### 3. Deploy

```bash
cd infra/envs/dev
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Smoke test

```bash
# Auto-fetches the API URL from Terraform output
bash scripts/smoke_test.sh
```

### 5. Destroy

```bash
terraform destroy
```

## Cost guardrails

- DynamoDB: PAY_PER_REQUEST (no idle cost)
- Lambda: outside VPC (no NAT Gateway)
- No provisioned concurrency
- $5/month budget alert — **set `budget_alert_email` before apply**

## Enabling Cognito auth

Add to `infra/envs/dev/dev.auto.tfvars`:

```hcl
enable_cognito = true
```

Then re-plan and apply:

```bash
terraform plan -out=tfplan && terraform apply tfplan
```

When enabled, `POST /items` and `GET /items/{id}` require a valid Cognito JWT in the `Authorization` header. `GET /health` remains public.

## Extending

- Add routes: extend `handler.py` and add `aws_apigatewayv2_route` resources in `modules/apigw_http_api/main.tf`
- Add DynamoDB attributes: update `modules/dynamodb_table/main.tf` and the IAM policy in `modules/iam/main.tf`
- Add environments: copy `infra/envs/dev/` to `infra/envs/prod/` and update the backend key

## 5-minute demo

After deploy, the API is live immediately. Real output from a working deployment:

```bash
$ bash scripts/smoke_test.sh

[1/3] Health check...
{ "status": "ok" }

[2/3] Create item...
{ "id": "item-1772683099" }

[3/3] Read item...
{ "id": "item-1772683099", "ts": "2026-03-05T03:58:19Z", "name": "demo" }

Smoke test passed.
```

Or hit the endpoints directly:

```bash
API_URL=$(terraform -chdir=infra/envs/dev output -raw api_base_url)

curl -s "$API_URL/health"
# {"status":"ok"}

curl -s -X POST "$API_URL/items" \
  -H "Content-Type: application/json" \
  -d '{"id":"abc","name":"my item"}'
# {"id":"abc"}

curl -s "$API_URL/items/abc"
# {"id":"abc","name":"my item","ts":"..."}
```

## More detail

See [docs/runbook.md](docs/runbook.md) for deploy, test, destroy, and troubleshooting steps.
