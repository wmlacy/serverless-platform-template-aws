variable "budget_name" {
  description = "Name of the AWS budget."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives budget alert notifications."
  type        = string
}
