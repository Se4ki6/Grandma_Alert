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
variable "dashboard_bucket_name" {
  description = "静的Webホスティング用S3バケット名（グローバルで一意）"
  type        = string
}

variable "tags" {
  description = "リソースに付与する共通タグ"
  type        = map(string)
  default = {
    Project   = "Grandma-Alert"
    ManagedBy = "Terraform"
  }
}
