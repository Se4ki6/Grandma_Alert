output "postback_invoke_url" {
  description = "LINE Postbackの受信URL"
  value       = "${aws_api_gateway_stage.postback.invoke_url}/postback"
}

output "lambda_function_name" {
  description = "Postback用Lambda関数名"
  value       = aws_lambda_function.rich_menu_postback.function_name
}
