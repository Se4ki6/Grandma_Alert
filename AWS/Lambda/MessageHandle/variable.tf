variable "region" {
  description = "AWSのリージョン名"
  type        = string
  default     = "ap-northeast-1"
}

variable "profile" {
  description = "AWSのプロファイル名"
  type        = string
}

variable "line_channel_access_token" {
  description = "LINEチャネルアクセストークン"
  type        = string
  sensitive   = true
}

variable "group_id" {
  description = "送信先のグループID"
  type        = string
}

variable "line_channel_secret" {
  description = "LINEチャネルシークレット（署名検証用）"
  type        = string
  sensitive   = true
}

variable "thing_name" {
  description = "IoT CoreのThing名"
  type        = string
  default     = "ElderlyCam_01"
}

variable "secret_name" {
  description = "Secrets Managerのシークレット名"
  type        = string
  default     = "LineRichMenu"
}


