// ---------------------------------------------
// S3: Images bucket (private)
// ---------------------------------------------
resource "aws_s3_bucket" "images" {
  bucket = var.images_bucket_name

  tags = merge(
    var.tags,
    {
      Name = "Images Bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images_expire" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "delete-old-images"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}

// ---------------------------------------------
// CORS設定（ブラウザからのアクセス用）
// ---------------------------------------------
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] // テスト用。本番環境ではCloudFrontドメインに限定
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

// ---------------------------------------------
// パブリックアクセスブロック設定（テスト用に緩和）
// ---------------------------------------------
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = false // テスト用。本番環境ではtrue推奨
  block_public_policy     = false // テスト用。本番環境ではtrue推奨
  ignore_public_acls      = false // テスト用。本番環境ではtrue推奨
  restrict_public_buckets = false // テスト用。本番環境ではtrue推奨
}

// ---------------------------------------------
// バケットポリシー（読み取り専用パブリックアクセス）
// ---------------------------------------------
resource "aws_s3_bucket_policy" "images_public_read" {
  bucket = aws_s3_bucket.images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.images.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.images]
}

// ---------------------------------------------
// S3 Event Notification to Lambda
// ---------------------------------------------
locals {
  # 監視したい拡張子のリスト
  target_suffixes = [".jpg", ".jpeg", ".png", ".gif"]
}

resource "aws_s3_bucket_notification" "images_upload_trigger" {
  bucket = aws_s3_bucket.images.id

  # リストの分だけ lambda_function ブロックを生成
  dynamic "lambda_function" {
    for_each = local.target_suffixes
    content {
      lambda_function_arn = var.line_notification_lambda_arn
      events              = ["s3:ObjectCreated:*"]
      filter_suffix       = lambda_function.value # ここでリストの値が参照される
    }
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

// Lambda Permission for S3 to invoke
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.line_notification_lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}
