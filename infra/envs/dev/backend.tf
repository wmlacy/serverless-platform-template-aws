terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Partial backend configuration — supply the rest via:
  #   terraform init -backend-config=backend.hcl
  # See backend.hcl.example for the required values.
  backend "s3" {}
}
