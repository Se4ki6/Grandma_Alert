variable "region" {
  description = "AWSのリージョン名"
  type        = string
  default     = "ap-northeast-1"
}
variable "profile" {
  description = "AWSのプロファイル名"
  type        = string
  default     = "AdministratorAccess-522814702929"
}

//---------------------------------------------
// secretsmanager.tf
//---------------------------------------------
variable "name" {
  description = "シークレットの項目「名前」"
  type        = string
}

variable "address" {
  description = "シークレットの項目「住所」"
  type        = string
}

variable "disease" {
  description = "シークレットの項目「病名」"
  type        = string
}





