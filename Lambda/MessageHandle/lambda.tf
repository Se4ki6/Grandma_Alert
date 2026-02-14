# ---------------------------------------------
# データソース
# ---------------------------------------------
# アカウントID取得
data "aws_caller_identity" "current" {}

# Secrets Managerのシークレット情報を取得
data "aws_secretsmanager_secret" "emergency_info" {
  name = var.secret_name
}

# ---------------------------------------------
# Lambda関数
# ---------------------------------------------
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

# Secrets ManagerとIoT Coreへのアクセス権限
resource "aws_iam_role_policy" "lambda_policy" {
  name = "line_rich_menu_postback_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Secrets Manager 読み取り権限
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = data.aws_secretsmanager_secret.emergency_info.arn
      },
      # IoT Core Shadow 更新権限
      {
        Effect   = "Allow"
        Action   = ["iot:UpdateThingShadow", "iot:GetThingShadow"]
        Resource = "arn:aws:iot:${var.region}:${data.aws_caller_identity.current.account_id}:thing/${var.thing_name}"
      }
    ]
  })
}

resource "aws_lambda_function" "rich_menu_postback" {
  filename         = data.archive_file.postback_zip.output_path
  function_name    = "line_rich_menu_postback"
  role             = aws_iam_role.lambda_role.arn
  handler          = "postback_handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  source_code_hash = data.archive_file.postback_zip.output_base64sha256

  environment {
    variables = {
      LINE_CHANNEL_ACCESS_TOKEN = var.line_channel_access_token
      LINE_CHANNEL_SECRET       = var.line_channel_secret
      GROUP_ID                  = var.group_id
      THING_NAME                = var.thing_name
      SECRET_ID                 = data.aws_secretsmanager_secret.emergency_info.id
    }
  }
}

resource "aws_cloudwatch_log_group" "postback_log" {
  name              = "/aws/lambda/${aws_lambda_function.rich_menu_postback.function_name}"
  retention_in_days = 1
}
