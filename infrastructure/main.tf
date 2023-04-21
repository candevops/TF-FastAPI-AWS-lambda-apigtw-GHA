terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.47.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "BR_lambda" {
  function_name = var.lambda_function_name
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.main.lambda_handler"
  filename      = "../my-deployment-package.zip"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.BR_loggroup,
  ]
}


resource "aws_cloudwatch_log_group" "BR_loggroup" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "BR_api" {
  name = "BR_api"
}

resource "aws_api_gateway_resource" "BR_resource" {
  rest_api_id = aws_api_gateway_rest_api.BR_api.id
  parent_id   = aws_api_gateway_rest_api.BR_api.root_resource_id
  path_part   = var.endpoint_path
}

resource "aws_api_gateway_method" "BR_method" {
  rest_api_id   = aws_api_gateway_rest_api.BR_api.id
  resource_id   = aws_api_gateway_resource.BR_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.BR_api.id
  resource_id             = aws_api_gateway_resource.BR_resource.id
  http_method             = aws_api_gateway_method.BR_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.BR_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.BR_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.BR_api.id}/*/${aws_api_gateway_method.BR_method.http_method}${aws_api_gateway_resource.BR_resource.path}"
}

resource "aws_api_gateway_deployment" "BR_loggroup" {
  rest_api_id = aws_api_gateway_rest_api.BR_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.BR_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.BR_method, aws_api_gateway_integration.integration]

}

resource "aws_api_gateway_stage" "BR_loggroup" {
  deployment_id = aws_api_gateway_deployment.BR_loggroup.id
  rest_api_id   = aws_api_gateway_rest_api.BR_api.id
  stage_name    = "dev"
}