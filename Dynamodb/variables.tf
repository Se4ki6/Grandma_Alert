variable "dynamodb_table_name" {
  description = "DynamoDBテーブル名"
  type        = string
  default     = "EmergencyInfo"
}

variable "seed_house_id" {
  description = "house_id"
  type        = string
}

variable "seed_address" {
  description = "住所"
  type        = string
}

variable "seed_chronic_disease" {
  description = "持病"
  type        = string
}
