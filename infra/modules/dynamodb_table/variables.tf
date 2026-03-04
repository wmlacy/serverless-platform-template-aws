variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
