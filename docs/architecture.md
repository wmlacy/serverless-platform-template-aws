# Architecture

## Data flow

```
Client
  │
  │  HTTPS request
  ▼
API Gateway (HTTP API)
  │  payload format 2.0
  │  routes: GET /health, POST /items, GET /items/{id}
  │  optional JWT auth via Cognito (enable_cognito = true)
  ▼
Lambda Function (Python 3.12)
  │  handler.py — reads X-Correlation-Id, logs JSON, returns structured response
  │  env var: TABLE_NAME
  ▼
DynamoDB Table
  │  hash key: id (string)
  │  billing: PAY_PER_REQUEST
  │  SSE: enabled (AWS-owned key)
  ▼
Response → Client
  headers: Content-Type, X-Correlation-Id
```

## Supporting resources

```
CloudWatch Log Group (/aws/lambda/<function>)
  └─ retention: 14 days
  └─ alarm: Lambda errors > 0

CloudWatch Log Group (/aws/apigateway/<api>)
  └─ retention: 14 days
  └─ alarm: 5XX rate > 1%, p99 latency > 2s

AWS Budgets
  └─ $5/month ACTUAL threshold → email alert
```

## Security guardrails

| Control | Detail |
|---|---|
| IAM least-privilege | Lambda role allows only `dynamodb:GetItem`, `dynamodb:PutItem` on this table + `logs:CreateLogStream`, `logs:PutLogEvents` on this log group |
| No VPC | Lambda runs outside VPC — no NAT Gateway, no idle cost |
| No provisioned concurrency | Cold starts acceptable for a portfolio/low-traffic API |
| SSE on DynamoDB | Enabled with AWS-owned KMS key — no extra cost |
| S3 state bucket | Versioning + AES256 encryption + public access block |
| Budget alert | Hard stop at $5/month — email triggered at 100% actual spend |

## Cost guardrails

| Resource | Billing model | Idle cost |
|---|---|---|
| Lambda | Per invocation + GB-sec | $0 |
| DynamoDB | PAY_PER_REQUEST | $0 |
| API Gateway | Per request | $0 |
| CloudWatch Logs | Per GB ingested | ~$0 at low volume |
| Budget | Free | $0 |
