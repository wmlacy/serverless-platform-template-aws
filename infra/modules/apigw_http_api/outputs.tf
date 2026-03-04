output "api_id" {
  description = "ID of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base URL of the deployed API (e.g. https://<id>.execute-api.us-east-1.amazonaws.com)."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway (used for Lambda permission source_arn)."
  value       = aws_apigatewayv2_api.this.execution_arn
}
