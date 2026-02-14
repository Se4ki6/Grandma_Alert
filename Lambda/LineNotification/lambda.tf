# コードをZip化
data "archive_file" "dummy_zip" {
  type        = "zip"
  source_file = "python/line.py"
  output_path = "python/line.zip"
}

# Lambda本体
resource "aws_lambda_function" "send_line" {
  filename         = data.archive_file.dummy_zip.output_path
  function_name    = "send_line_notification"
  role             = aws_iam_role.lambda_role.arn
  handler          = "line.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.dummy_zip.output_base64sha256

  environment {
    variables = {
      LINE_CHANNEL_ACCESS_TOKEN = var.line_channel_access_token
      GROUP_ID                  = var.group_id
      IMAGE_GALLERY_URL         = var.image_gallery_url
    }
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "send_line" {
  function_name      = aws_lambda_function.send_line.function_name
  authorization_type = "NONE"
}

# IAM Role (Logsへの書き込み権限)
resource "aws_iam_role" "lambda_role" {
  name = "line_bot_send_line_role"

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

# S3からの読み取り権限
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ロググループを明示的に作成 (terraform destroyで消えるように)
# ログは1日で削除
resource "aws_cloudwatch_log_group" "trap_log" {
  name              = "/aws/lambda/${aws_lambda_function.send_line.function_name}"
  retention_in_days = 1
}
