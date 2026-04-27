variable "region" {
  description = "AWSのリージョン名"
  type        = string
  default     = "ap-northeast-1"
}

variable "profile" {
  description = "AWSのプロファイル名"
  type        = string
}

variable "stage_name" {
  description = "API Gatewayのステージ名"
  type        = string
  default     = "prod"
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

variable "report_name" {
  description = "通報テンプレートの氏名"
  type        = string
}

variable "report_address" {
  description = "通報テンプレートの住所"
  type        = string
}

variable "report_disease" {
  description = "通報テンプレートの既往症"
  type        = string
}
