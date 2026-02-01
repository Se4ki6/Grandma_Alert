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
// lambda.tf
// ---------------------------------------------
variable "cloudfront_domain" {
  description = "CloudFrontディストリビューションのドメイン名"
  type        = string
}

variable "cloudfront_key_pair_id" {
  description = "CloudFront Key Pair ID"
  type        = string
}

variable "private_key_ssm_param" {
  description = "SSMパラメータストアに保存した秘密鍵のパラメータ名"
  type        = string
  default     = "/cloudfront/private-key"
}

variable "url_expiration_minutes" {
  description = "署名付きURLの有効期限（分）"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch Logsの保持期間（日）"
  type        = number
  default     = 7
}

variable "tags" {
  description = "リソースに付与する共通タグ"
  type        = map(string)
  default = {
    Project   = "Grandma-Alert"
    ManagedBy = "Terraform"
  }
}
