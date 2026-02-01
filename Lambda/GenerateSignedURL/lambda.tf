# コードをZip化（依存ライブラリを含む）
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/lambda_function.zip"

  depends_on = [null_resource.pip_install]
}

# 依存ライブラリをインストール
resource "null_resource" "pip_install" {
  triggers = {
    requirements = filemd5("${path.module}/requirements.txt")
    lambda_code  = filemd5("${path.module}/lambda_function.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ${path.module}/package
      mkdir -p ${path.module}/package
      pip install -r ${path.module}/requirements.txt -t ${path.module}/package/
      cp ${path.module}/lambda_function.py ${path.module}/package/
    EOT
  }
}

# IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "GenerateSignedURL_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# CloudWatch Logs権限
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SSMパラメータストアへのアクセス権限
resource "aws_iam_role_policy" "ssm_access" {
  name = "SSMParameterAccess"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.region}:*:parameter${var.private_key_ssm_param}"
      }
    ]
  })
}

# Lambda関数
resource "aws_lambda_function" "generate_signed_url" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "GenerateSignedURL"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLOUDFRONT_DOMAIN      = var.cloudfront_domain
      CLOUDFRONT_KEY_PAIR_ID = var.cloudfront_key_pair_id
      PRIVATE_KEY_SSM_PARAM  = var.private_key_ssm_param
      URL_EXPIRATION_MINUTES = var.url_expiration_minutes
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "GenerateSignedURL Lambda"
    }
  )
}

# CloudWatch Logsグループ
resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.generate_signed_url.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda URL（オプション：簡易的なHTTPSエンドポイント）
resource "aws_lambda_function_url" "signed_url_endpoint" {
  function_name      = aws_lambda_function.generate_signed_url.function_name
  authorization_type = "NONE" # 注意: 本番環境ではIAM認証またはAPI Gatewayを推奨

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST", "GET"]
    allow_headers     = ["*"]
    max_age           = 3600
  }
}
