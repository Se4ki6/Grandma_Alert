output "lambda_function_arn" {
  value       = aws_lambda_function.generate_signed_url.arn
  description = "Lambda関数のARN"
}

output "lambda_function_name" {
  value       = aws_lambda_function.generate_signed_url.function_name
  description = "Lambda関数名"
}

output "lambda_function_url" {
  value       = aws_lambda_function_url.signed_url_endpoint.function_url
  description = "Lambda Function URL（HTTPSエンドポイント）"
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "Lambda実行ロールのARN"
}
