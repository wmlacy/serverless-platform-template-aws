variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role the Lambda function assumes."
  type        = string
}

variable "source_dir" {
  description = "Filesystem path to the directory containing the Lambda source code. Zipped at plan time by archive_file."
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name injected as the TABLE_NAME environment variable."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
