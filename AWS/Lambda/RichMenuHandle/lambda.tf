data "archive_file" "postback_zip" {
  type        = "zip"
  source_file = "lambda_code/postback_handler.py"
  output_path = "lambda_code/postback_handler.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "line_rich_menu_postback_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "rich_menu_postback" {
  filename         = data.archive_file.postback_zip.output_path
  function_name    = "line_rich_menu_postback"
  role             = aws_iam_role.lambda_role.arn
  handler          = "postback_handler.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.postback_zip.output_base64sha256

  environment {
    variables = {
      LINE_CHANNEL_ACCESS_TOKEN = var.line_channel_access_token
      GROUP_ID                  = var.group_id
      REPORT_NAME               = var.report_name
      REPORT_ADDRESS            = var.report_address
      REPORT_DISEASE            = var.report_disease
      REPORT_DISSEASE           = var.report_disease
    }
  }
}

resource "aws_cloudwatch_log_group" "postback_log" {
  name              = "/aws/lambda/${aws_lambda_function.rich_menu_postback.function_name}"
  retention_in_days = 1
}

resource "aws_api_gateway_rest_api" "rich_menu_api" {
  name = "rich_menu_postback_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "postback" {
  rest_api_id = aws_api_gateway_rest_api.rich_menu_api.id
  parent_id   = aws_api_gateway_rest_api.rich_menu_api.root_resource_id
  path_part   = "postback"
}

resource "aws_api_gateway_method" "postback" {
  rest_api_id   = aws_api_gateway_rest_api.rich_menu_api.id
  resource_id   = aws_api_gateway_resource.postback.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "postback" {
  rest_api_id             = aws_api_gateway_rest_api.rich_menu_api.id
  resource_id             = aws_api_gateway_resource.postback.id
  http_method             = aws_api_gateway_method.postback.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rich_menu_postback.invoke_arn
}

resource "aws_api_gateway_deployment" "postback" {
  rest_api_id = aws_api_gateway_rest_api.rich_menu_api.id

  triggers = {
    redeployment = sha1(jsonencode({
      method      = aws_api_gateway_method.postback.id
      integration = aws_api_gateway_integration.postback.id
    }))
  }

  depends_on = [
    aws_api_gateway_integration.postback,
    aws_lambda_permission.apigw_invoke
  ]
}

resource "aws_api_gateway_stage" "postback" {
  deployment_id = aws_api_gateway_deployment.postback.id
  rest_api_id   = aws_api_gateway_rest_api.rich_menu_api.id
  stage_name    = var.stage_name
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rich_menu_postback.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rich_menu_api.execution_arn}/*/*"
}
