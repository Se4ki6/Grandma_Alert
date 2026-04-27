data "aws_caller_identity" "current" {} # 現在のAWSアカウント情報を取得

resource "aws_secretsmanager_secret" "secret" {
  name        = "LineEmergencyInfo"
  description = "LineEmergencyInfo用シークレット"
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    name    = var.name
    address = var.address
    disease = var.disease
  })
}

data "aws_iam_policy_document" "resource_policy" {
  #   # 現在のAWSアカウントからのアクセス許可
  #   statement {
  #     sid    = "EnableAnotherAWSAccountToReadTheSecret"
  #     effect = "Allow"

  #     principals {
  #       type        = "AWS"
  #       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  #     }

  #     actions   = ["secretsmanager:GetSecretValue"]
  #     resources = ["*"]
  #   }
  # Lambda 実行ロールを許可
  statement {
    sid    = "AllowSpecificLambdaFunctionToReadSecret"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:send_line_notification"
      ]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "resource_policy" {
  secret_arn = aws_secretsmanager_secret.secret.arn
  policy     = data.aws_iam_policy_document.resource_policy.json
}
