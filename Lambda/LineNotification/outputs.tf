// ---------------------------------------------
// Outputs for Lambda Function
// ---------------------------------------------
output "lambda_function_arn" {
  description = "LINE通知Lambda関数のARN"
  value       = aws_lambda_function.send_line.arn
}

output "lambda_function_name" {
  description = "LINE通知Lambda関数の名前"
  value       = aws_lambda_function.send_line.function_name
}
