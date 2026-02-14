output "webhook_invoke_url" {
  description = "LINE Webhookの受信URL"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/webhook"
}

output "lambda_function_name" {
  description = "Postback用Lambda関数名"
  value       = aws_lambda_function.rich_menu_postback.function_name
}
