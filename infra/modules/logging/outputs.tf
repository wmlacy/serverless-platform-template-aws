output "log_group_name" {
  description = "Name of the Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the Lambda CloudWatch log group. Used by the IAM module to scope log write permissions."
  value       = aws_cloudwatch_log_group.lambda.arn
}
