provider "aws" {
  region = "" # change Region
}

# DynamoDB Table
resource "aws_dynamodb_table" "go_serverless_yt_table" {
  name           = "go-serverless-yt"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  attribute {
    name = "email"
    type = "S"
  }
}

# Lambda Function
resource "aws_lambda_function" "go_serverless_yt" {
  function_name    = "go-serverless-yt"
  handler          = "main"
  runtime          = "go1.x"
  filename         = "deployment.zip"
  role             = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("deployment.zip")

  depends_on = [aws_dynamodb_table.go_serverless_yt_table]
}

# Lambda Environment Variables
resource "aws_lambda_function_environment" "go_serverless_yt_env" {
  function_name = aws_lambda_function.go_serverless_yt.function_name
  variables = {
    AWS_REGION = "" # Region ...
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "go_serverless_yt_api" {
  name          = "go-serverless-yt-api"
  protocol_type = "HTTP"
}

# Lambda Integration with API Gateway
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.go_serverless_yt_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.go_serverless_yt.invoke_arn
}

# Route in API Gateway
resource "aws_apigatewayv2_route" "go_serverless_yt_route" {
  api_id    = aws_apigatewayv2_api.go_serverless_yt_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deployment of API Gateway
resource "aws_apigatewayv2_stage" "go_serverless_yt_stage" {
  api_id = aws_apigatewayv2_api.go_serverless_yt_api.id
  name   = "prod"
}
