variable "region" {
  description = "AWSのリージョン名"
  type        = string
  default     = "ap-northeast-1"
}
variable "profile" {
  description = "AWSのプロファイル名"
  type        = string
}

//---------------------------------------------
// apigateway.tf
//---------------------------------------------
variable "apigateway_name" {
  description = "API Gatewayの名前"
  type        = string
  default     = "line_bot_trap_api"
}
