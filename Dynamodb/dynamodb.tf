// ---------------------------------------------
// DynamoDB
// ---------------------------------------------
resource "aws_dynamodb_table" "emergency_info" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "house_id"

  attribute {
    name = "house_id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "seed" {
  table_name = aws_dynamodb_table.emergency_info.name
  hash_key   = aws_dynamodb_table.emergency_info.hash_key

  item = jsonencode({
    house_id        = { S = var.seed_house_id }
    address         = { S = var.seed_address }
    chronic_disease = { S = var.seed_chronic_disease }
  })
}
