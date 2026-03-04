data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "/tmp/${var.function_name}_lambda.zip"
}

resource "aws_lambda_function" "api" {
  function_name    = var.function_name
  role             = var.execution_role_arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Conservative defaults — cheap and sufficient for a CRUD API.
  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  # Explicitly no vpc_config block — Lambda runs outside VPC.
  # No NAT Gateway = no surprise bills.

  # Explicitly no provisioned_concurrency_config block.

  tags = var.tags
}
