# Log group must be created before the Lambda function so AWS uses this
# retention policy rather than defaulting to "Never expire".
resource "aws_cloudwatch_log_group" "lambda" {
  name              = var.log_group_name
  retention_in_days = 14

  tags = var.tags
}

# Lambda errors alarm — uses function name as a plain string so this module
# has no data-flow dependency on modules/lambda_api (avoids circular dep).
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda invocation errors > 0 in the last 60 s"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = var.tags
}
