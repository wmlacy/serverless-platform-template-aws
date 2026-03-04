provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  prefix = "${var.project_slug}-${var.env}"

  common_tags = {
    Project     = var.project_slug
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# ── DynamoDB ──────────────────────────────────────────────────────────────────

module "dynamodb" {
  source     = "../../modules/dynamodb_table"
  table_name = "${local.prefix}-items"
}

# ── CloudWatch log group + Lambda errors alarm ────────────────────────────────
# Created before Lambda so AWS uses our retention policy instead of defaulting
# to "Never expire". Transitive dependency chain (logging → iam → lambda)
# ensures correct ordering without explicit depends_on.

module "logging" {
  source               = "../../modules/logging"
  log_group_name       = "/aws/lambda/${local.prefix}-api"
  lambda_function_name = "${local.prefix}-api"
  prefix               = local.prefix
}

# ── IAM ───────────────────────────────────────────────────────────────────────
# Least-privilege: read/write the items table + write to the Lambda log group.

module "iam" {
  source             = "../../modules/iam"
  role_name          = "${local.prefix}-lambda-exec"
  policy_name        = "${local.prefix}-lambda-policy"
  dynamodb_table_arn = module.dynamodb.table_arn
  log_group_arn      = module.logging.log_group_arn
}

# ── Lambda ────────────────────────────────────────────────────────────────────
# Depends on iam (data flow) which depends on logging (data flow), so the log
# group is guaranteed to exist before the function is created.

module "lambda" {
  source             = "../../modules/lambda_api"
  function_name      = "${local.prefix}-api"
  execution_role_arn = module.iam.lambda_exec_role_arn
  source_dir         = "${path.root}/../../../services/api/src"
  table_name         = module.dynamodb.table_name
}

# ── Cognito (optional) ────────────────────────────────────────────────────────

module "cognito" {
  count          = var.enable_cognito ? 1 : 0
  source         = "../../modules/cognito_jwt_auth"
  user_pool_name = "${local.prefix}-user-pool"
  client_name    = "${local.prefix}-app-client"
}

# ── API Gateway ───────────────────────────────────────────────────────────────

module "apigw" {
  source               = "../../modules/apigw_http_api"
  api_name             = "${local.prefix}-api"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  enable_cognito       = var.enable_cognito
  # try() returns "" when the cognito module has count = 0, which is safe
  # because these values are only used when enable_cognito = true.
  cognito_client_id  = try(module.cognito[0].client_id, "")
  cognito_issuer_url = try(module.cognito[0].issuer_url, "")
}

# ── API Gateway alarms ────────────────────────────────────────────────────────
# Defined here (not in modules/logging) to avoid a circular module dependency:
#   logging → apigw → lambda → logging
# The Lambda errors alarm lives in modules/logging.

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.prefix}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "API Gateway 5XX errors > 0 in the last 60 s"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = module.apigw.api_id
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency_p99" {
  alarm_name          = "${local.prefix}-api-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGateway"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 2000
  alarm_description   = "API Gateway p99 integration latency > 2000 ms"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = module.apigw.api_id
  }
}

# ── AWS Budget ($5/month) ─────────────────────────────────────────────────────

module "budgets" {
  source      = "../../modules/budgets"
  budget_name = "${local.prefix}-monthly-budget"
  alert_email = var.budget_alert_email
}
