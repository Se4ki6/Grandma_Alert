resource "aws_apigatewayv2_api" "http_api" {
  name          = var.apigateway_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.trap_function.invoke_arn
}

resource "aws_apigatewayv2_route" "any" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /" # LINEからはPOSTで来る
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# LambdaにAPIGatewayからの起動を許可
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trap_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
