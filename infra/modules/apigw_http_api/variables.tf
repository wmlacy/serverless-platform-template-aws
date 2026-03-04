variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function (used by the API Gateway integration)."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (used in the Lambda permission resource)."
  type        = string
}

variable "enable_cognito" {
  description = "When true, routes are protected by a Cognito JWT authorizer."
  type        = bool
  default     = false
}

variable "cognito_client_id" {
  description = "Cognito user pool client ID. Required when enable_cognito = true."
  type        = string
  default     = ""
}

variable "cognito_issuer_url" {
  description = "Cognito issuer URL. Required when enable_cognito = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
