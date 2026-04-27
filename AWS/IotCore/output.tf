# ---------------------------------------------
# Output (エンドポイント表示)
# ---------------------------------------------
# ラズパイのコードに埋め込むエンドポイントURLを取得
data "aws_iot_endpoint" "endpoint" {
  endpoint_type = "iot:Data-ATS"
}

output "iot_endpoint" {
  value = data.aws_iot_endpoint.endpoint.endpoint_address
}
