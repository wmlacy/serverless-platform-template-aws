variable "log_group_name" {
  description = "CloudWatch log group name for the Lambda function."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name used in the errors alarm dimension. Passed as a plain string — not a resource reference — to avoid circular module dependencies."
  type        = string
}

variable "prefix" {
  description = "Resource name prefix (project_slug-env) used for alarm names."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
