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
  description = "LINEチャネルのアクセストークン"
  type        = string
  sensitive   = true
}

variable "group_id" {
  description = "メッセージ送信先のグループID（Gから始まるID）"
  type        = string
}

variable "image_gallery_url" {
  description = "画像一覧ページのURL"
  type        = string
}
