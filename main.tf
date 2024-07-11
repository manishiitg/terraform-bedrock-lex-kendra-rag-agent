# Configure the AWS provider
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

# EventBridge rule for Security Hub findings
resource "aws_cloudwatch_event_rule" "security_hub_event_rule" {
  description = "EventBridge rule for Security Hub findings"
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
  })
  state = "ENABLED"
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub_event_rule.arn
}

# Archive file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "demo-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 500
  memory_size      = 256
  description      = "Demo lambda"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.libs.arn]
}

# Archive file for Lambda Layer
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function/package"
  output_path = "${path.module}/function/package/layer.zip"
}

# Lambda Layer
resource "aws_lambda_layer_version" "libs" {
  filename            = "function/package/layer.zip"  # Ensure you zip your layer content
  layer_name          = "blank-python-lib"
  compatible_runtimes = ["python3.8"]
  description         = "Dependencies for the blank-python sample app."
}
# IAM role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda execution
resource "aws_iam_role_policy" "lambda_execution_policy" {
  name = "lambda_execution_policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM policy for Bedrock access
resource "aws_iam_role_policy" "bedrock_invoke_model_policy" {
  name = "bedrock_invoke_model_policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      }
    ]
  })
}

# Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda Function"
  value       = aws_lambda_function.function.arn
}

output "security_hub_event_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.security_hub_event_rule.arn
}