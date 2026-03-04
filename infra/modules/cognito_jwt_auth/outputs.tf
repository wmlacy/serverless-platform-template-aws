output "user_pool_id" {
  description = "ID of the Cognito user pool."
  value       = aws_cognito_user_pool.this.id
}

output "client_id" {
  description = "ID of the Cognito user pool client."
  value       = aws_cognito_user_pool_client.this.id
}

output "issuer_url" {
  description = "JWT issuer URL used by API Gateway to validate tokens."
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}
