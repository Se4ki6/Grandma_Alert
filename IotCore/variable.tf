//---------------------------------------------
// provider.tf
//---------------------------------------------
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
// iot.tf
//---------------------------------------------
variable "thing_name" {
  description = "IoT CoreのThing名"
  type        = string
}
