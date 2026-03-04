variable "role_name" {
  description = "Name of the Lambda IAM execution role."
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM policy attached to the execution role."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table the Lambda is allowed to read/write."
  type        = string
}

variable "log_group_arn" {
  description = "ARN of the CloudWatch log group the Lambda is allowed to write to."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
