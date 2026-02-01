# ---------------------------------------------
#  1.IoT Thing (モノ) の作成
# ---------------------------------------------
resource "aws_iot_thing" "main" {
  name = var.thing_name
}

# ---------------------------------------------
# 2. IoT Policy (ポリシー) の作成
# ---------------------------------------------
resource "aws_iot_policy" "main" {
  name = "${var.thing_name}_Policy"
  # 開発用: 一旦すべてのリソース(*)に対して許可を与えています。
  # 本番運用時は "Resource": "arn:aws:iot:REGION:ACCOUNT:topic/..." のように絞るのがベストです。
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------
# 3. Certificate (証明書) の発行
# ---------------------------------------------
resource "aws_iot_certificate" "cert" {
  active = true
}

# ---------------------------------------------
# 4. アタッチ (紐付け)
# ---------------------------------------------

# ポリシーを証明書にアタッチ
resource "aws_iot_policy_attachment" "att_policy" {
  policy = aws_iot_policy.main.name
  target = aws_iot_certificate.cert.arn
}

# 証明書をモノにアタッチ
resource "aws_iot_thing_principal_attachment" "att_thing" {
  principal = aws_iot_certificate.cert.arn
  thing     = aws_iot_thing.main.name
}

# ---------------------------------------------
# 5. ファイル出力 (ラズパイ転送用)
# ---------------------------------------------

# 証明書 (Certificate)
resource "local_file" "cert_pem" {
  content  = aws_iot_certificate.cert.certificate_pem
  filename = "${path.module}/certs/certificate.pem.crt"
}

# 秘密鍵 (Private Key)
resource "local_file" "private_key" {
  content  = aws_iot_certificate.cert.private_key
  filename = "${path.module}/certs/private.pem.key"
}

# 公開鍵 (Public Key) - 通常あまり使いませんが念のため
resource "local_file" "public_key" {
  content  = aws_iot_certificate.cert.public_key
  filename = "${path.module}/certs/public.pem.key"
}

# Root CA (AmazonRootCA1.pem) のダウンロード
# ※ Mac/Linux用です。Windowsの場合はPowerShell等のコマンドに書き換えるか、手動ダウンロードしてください。
resource "null_resource" "download_root_ca" {
  provisioner "local-exec" {
    command = "curl -o ${path.module}/certs/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem"
  }
}
