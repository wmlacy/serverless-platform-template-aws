resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"

  tags = var.tags
}

# Access logs for API Gateway — separate log group from the Lambda log group.
resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.responseLatency"
      ip             = "$context.identity.sourceIp"
    })
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# JWT authorizer — only created when enable_cognito = true.
resource "aws_apigatewayv2_authorizer" "jwt" {
  count            = var.enable_cognito ? 1 : 0
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.api_name}-jwt"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_issuer_url
  }
}

locals {
  authorizer_id = var.enable_cognito ? aws_apigatewayv2_authorizer.jwt[0].id : null
  auth_type     = var.enable_cognito ? "JWT" : "NONE"
}

# GET /health — always public.
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = "NONE"
}

# POST /items — protected when Cognito is enabled.
resource "aws_apigatewayv2_route" "post_items" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = local.auth_type
  authorizer_id      = local.authorizer_id
}

# GET /items/{id} — protected when Cognito is enabled.
resource "aws_apigatewayv2_route" "get_item" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = local.auth_type
  authorizer_id      = local.authorizer_id
}

# Allow API Gateway to invoke the Lambda function.
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
