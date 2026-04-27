// ---------------------------------------------
// provider.tf
// ---------------------------------------------
variable "region" {
  description = "AWSのリージョン名"
  type        = string
}

variable "profile" {
  description = "AWSの認証プロファイル名"
  type        = string
}

// ---------------------------------------------
// s3.tf
// ---------------------------------------------
variable "images_bucket_name" {
  description = "画像保存用S3バケット名（グローバルで一意）"
  type        = string
}

variable "lifecycle_expiration_days" {
  description = "画像の自動削除までの日数"
  type        = number
  default     = 1
}

variable "tags" {
  description = "リソースに付与する共通タグ"
  type        = map(string)
  default = {
    Project   = "Grandma-Alert"
    ManagedBy = "Terraform"
  }
}

// ---------------------------------------------
// Lambda関連
// ---------------------------------------------
variable "line_notification_lambda_arn" {
  description = "LINE通知用Lambda関数のARN"
  type        = string
}

variable "line_notification_lambda_name" {
  description = "LINE通知用Lambda関数の名前"
  type        = string
}

variable "dashboard_cloudfront_domain" {
  description = "Dashboard用CloudFrontドメイン（CORS許可用）"
  type        = string
  default     = "d2zaynqig5sahs.cloudfront.net"
}
