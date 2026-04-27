# ---------------------------------------------
# 鍵の中身を出力 (重要！)
# ---------------------------------------------
output "pi_access_key_id" {
  description = "Raspberry Pi用IAMユーザーのアクセスキーID"
  value       = aws_iam_access_key.pi_key.id
}

output "pi_secret_access_key" {
  description = "Raspberry Pi用IAMユーザーのシークレットアクセスキー"
  value       = aws_iam_access_key.pi_key.secret
  sensitive   = true # コンソールに直接表示されないように隠す
}

output "pi_user_name" {
  description = "Raspberry Pi用IAMユーザー名"
  value       = aws_iam_user.pi_user.name
}

output "pi_user_arn" {
  description = "Raspberry Pi用IAMユーザーのARN"
  value       = aws_iam_user.pi_user.arn
}
