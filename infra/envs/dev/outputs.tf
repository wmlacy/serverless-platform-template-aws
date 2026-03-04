output "api_base_url" {
  description = "Base URL of the API Gateway HTTP API. Use this with smoke_test.sh."
  value       = module.apigw.api_endpoint
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB items table."
  value       = module.dynamodb.table_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "lambda_log_group" {
  description = "CloudWatch log group for the Lambda function."
  value       = module.logging.log_group_name
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (only set when enable_cognito = true)."
  value       = var.enable_cognito ? module.cognito[0].user_pool_id : null
}

output "cognito_client_id" {
  description = "Cognito App Client ID (only set when enable_cognito = true)."
  value       = var.enable_cognito ? module.cognito[0].client_id : null
}
