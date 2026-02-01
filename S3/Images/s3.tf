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
