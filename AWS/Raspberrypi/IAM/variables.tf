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
// iam.tf
// ---------------------------------------------
variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックス）"
  type        = string
}

variable "camera_storage_bucket_arn" {
  description = "カメラ画像保存用S3バケットのARN"
  type        = string
}
