variable "user_pool_name" {
  description = "Name of the Cognito user pool."
  type        = string
}

variable "client_name" {
  description = "Name of the Cognito user pool client."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
