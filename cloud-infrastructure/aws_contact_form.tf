# Contact form: API Gateway (HTTP API) -> Lambda (Node) -> DynamoDB

resource "aws_cloudwatch_log_group" "contact_form_api" {
  name              = "/aws/apigateway/contact-form"
  retention_in_days = 14
}

resource "aws_apigatewayv2_api" "contact_form" {
  name          = "contact-form"
  protocol_type = "HTTP"
  description   = "Contact form endpoint for bogolyandras.com"

  cors_configuration {
    allow_origins = ["https://www.bogolyandras.com"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_stage" "contact_form" {
  api_id      = aws_apigatewayv2_api.contact_form.id
  name        = "$default"
  auto_deploy = true

  # Applies to every route; requests over the limit get 429 before reaching Lambda
  default_route_settings {
    throttling_rate_limit  = 1
    throttling_burst_limit = 5
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.contact_form_api.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      requestTime        = "$context.requestTime"
      sourceIp           = "$context.identity.sourceIp"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      integrationError   = "$context.integrationErrorMessage"
    })
  }
}

data "archive_file" "contact_form" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/contact-form"
  output_path = "${path.module}/.build/contact-form.zip"
}

resource "aws_iam_role" "contact_form_lambda" {
  name = "contact-form-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_cloudwatch_log_group" "contact_form_lambda" {
  name              = "/aws/lambda/contact-form"
  retention_in_days = 14
}

# Only allow writing to its own log group, so the role can't create others
resource "aws_iam_role_policy" "contact_form_lambda_logs" {
  name = "logs"
  role = aws_iam_role.contact_form_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.contact_form_lambda.arn}:*"
    }]
  })
}

# Messages keyed by month (pk) and "<ISO timestamp>#<uuid>" (sk); items expire after 180 days via TTL
resource "aws_dynamodb_table" "contact_form" {
  name                        = "contact-form-messages"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = true

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Write-only: the function can add messages but never read or delete them
resource "aws_iam_role_policy" "contact_form_lambda_dynamodb" {
  name = "dynamodb"
  role = aws_iam_role.contact_form_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:PutItem"
      Resource = aws_dynamodb_table.contact_form.arn
    }]
  })
}

resource "aws_lambda_function" "contact_form" {
  function_name    = "contact-form"
  role             = aws_iam_role.contact_form_lambda.arn
  runtime          = "nodejs24.x"
  architectures    = ["arm64"]
  handler          = "index.handler"
  filename         = data.archive_file.contact_form.output_path
  source_code_hash = data.archive_file.contact_form.output_base64sha256
  memory_size      = 128
  timeout          = 5

  # Runtime update mode defaults to Auto: AWS patches Node itself; only the major version above is pinned

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.contact_form.name
    }
  }

  logging_config {
    # JSON adds level and requestId to every line and serializes errors with their stack
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
    log_group             = aws_cloudwatch_log_group.contact_form_lambda.name
  }

  depends_on = [
    aws_iam_role_policy.contact_form_lambda_logs,
    aws_iam_role_policy.contact_form_lambda_dynamodb,
  ]
}

resource "aws_apigatewayv2_integration" "contact_form" {
  api_id                 = aws_apigatewayv2_api.contact_form.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.contact_form.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "contact_form" {
  api_id    = aws_apigatewayv2_api.contact_form.id
  route_key = "POST /contact"
  target    = "integrations/${aws_apigatewayv2_integration.contact_form.id}"
}

resource "aws_lambda_permission" "contact_form_api" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.contact_form.execution_arn}/*/POST/contact"
}
