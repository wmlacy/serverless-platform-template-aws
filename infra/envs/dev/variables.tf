variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_slug" {
  description = "Short prefix applied to every resource name."
  type        = string
  default     = "spt"
}

variable "env" {
  description = "Deployment environment. Only 'dev' is supported in this template."
  type        = string
  default     = "dev"
}

variable "enable_cognito" {
  description = "Set to true to deploy a Cognito User Pool and protect /items routes with JWT auth."
  type        = bool
  default     = false
}

variable "budget_alert_email" {
  description = "Email address that receives the $5/month budget alert. Set this before apply — do not commit your real address."
  type        = string
  default     = "your-email@example.com"
}
