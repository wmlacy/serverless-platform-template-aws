# Serverless Platform Template (AWS)

A minimal, production-shaped serverless API on AWS using Terraform and Python 3.12. Costs under $5/month at low traffic.

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

### 2. Deploy

```bash
cd infra/envs/dev
terraform init -backend-config=backend.hcl
terraform apply -var="budget_alert_email=your-email@example.com"
```

### 3. Smoke test

```bash
bash scripts/smoke_test.sh <api_base_url>
```

### 4. Destroy

```bash
terraform destroy -var="budget_alert_email=your-email@example.com"
```

## Cost guardrails

- DynamoDB: PAY_PER_REQUEST (no idle cost)
- Lambda: outside VPC (no NAT Gateway)
- No provisioned concurrency
- $5/month budget alert — **set `budget_alert_email` before apply**

## Enabling Cognito auth

```bash
terraform apply \
  -var="enable_cognito=true" \
  -var="budget_alert_email=your-email@example.com"
```

When enabled, `POST /items` and `GET /items/{id}` require a valid Cognito JWT in the `Authorization` header. `GET /health` remains public.

## Extending

- Add routes: extend `handler.py` and add `aws_apigatewayv2_route` resources in `modules/apigw_http_api/main.tf`
- Add DynamoDB attributes: update `modules/dynamodb_table/main.tf` and the IAM policy in `modules/iam/main.tf`
- Add environments: copy `infra/envs/dev/` to `infra/envs/prod/` and update the backend key

## More detail

See [docs/runbook.md](docs/runbook.md) for deploy, test, destroy, and troubleshooting steps.
