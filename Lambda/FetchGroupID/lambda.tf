# コードをZip化
data "archive_file" "dummy_zip" {
  type        = "zip"
  source_file = "dummy.py"
  output_path = "dummy.zip"
}

# IAM Role (Logsへの書き込み権限)
resource "aws_iam_role" "lambda_role" {
  name = "line_bot_trap_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# CloudWatch Logs Full Access (簡易的にフルアクセス付与)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda本体
resource "aws_lambda_function" "trap_function" {
  filename         = data.archive_file.dummy_zip.output_path
  function_name    = "GetLineGroupId_Trap"
  role             = aws_iam_role.lambda_role.arn
  handler          = "dummy.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.dummy_zip.output_base64sha256
}

# ロググループを明示的に作成 (terraform destroyで消えるように)
resource "aws_cloudwatch_log_group" "trap_log" {
  name              = "/aws/lambda/${aws_lambda_function.trap_function.function_name}"
  retention_in_days = 1
}
