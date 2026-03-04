output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.api.arn
}

output "invoke_arn" {
  description = "Invoke ARN used by API Gateway to call the Lambda function."
  value       = aws_lambda_function.api.invoke_arn
}
