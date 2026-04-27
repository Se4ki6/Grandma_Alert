# 1. HTTP APIの作成 (REST APIより安くて速い)
resource "aws_apigatewayv2_api" "line_webhook" {
  name          = "LineWebhookApi"
  protocol_type = "HTTP"
}

# 2. Lambdaとつなぐ (インテグレーション)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.line_webhook.id
  integration_type       = "AWS_PROXY" # Lambdaにそのままリクエストを渡すモード
  integration_uri        = aws_lambda_function.rich_menu_postback.invoke_arn
  payload_format_version = "2.0"
}

# 3. ルート定義 (POST /webhook で待ち受け)
resource "aws_apigatewayv2_route" "post_webhook" {
  api_id    = aws_apigatewayv2_api.line_webhook.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# 4. デプロイステージ ($default は変更即反映)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.line_webhook.id
  name        = "$default"
  auto_deploy = true
}

# 5. 権限設定 (超重要: これがないとGatewayがLambdaを叩けない)
resource "aws_lambda_permission" "apigw_http" {
  statement_id  = "AllowAPIGatewayHttpInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rich_menu_postback.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.line_webhook.execution_arn}/*/*/webhook"
}
