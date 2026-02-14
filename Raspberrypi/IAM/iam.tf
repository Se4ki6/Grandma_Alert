# ---------------------------------------------
# ラズパイ専用のIAMユーザー (ロボット)
# ---------------------------------------------
resource "aws_iam_user" "pi_user" {
  name = "${var.project_name}_Device_User"
}

# ---------------------------------------------
# アクセスキーの発行 (IDとパスワード代わりの鍵)
# ---------------------------------------------
resource "aws_iam_access_key" "pi_key" {
  user = aws_iam_user.pi_user.name
}

# ---------------------------------------------
# 権限付与: S3への画像アップロードのみ許可
# ---------------------------------------------
resource "aws_iam_user_policy" "pi_s3_policy" {
  name = "${var.project_name}_S3_Upload_Policy"
  user = aws_iam_user.pi_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",   # アップロード
          "s3:PutObjectAcl" # 公開設定など(念のため)
        ]
        # 変数で指定したバケットのみを操作対象にする
        Resource = "${var.camera_storage_bucket_arn}/*"
      }
    ]
  })
}
