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
    allowed_origins = [
      "https://${aws_cloudfront_distribution.images.domain_name}", // Images用CloudFront
      "https://${var.dashboard_cloudfront_domain}"                 // Dashboard用CloudFront（署名付きURLでも動作）
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

// ---------------------------------------------
// パブリックアクセスブロック設定（テスト用に緩和）
// ---------------------------------------------
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// ---------------------------------------------
// バケットポリシー（CloudFrontからの読み取り専用アクセス）
// ---------------------------------------------
resource "aws_s3_bucket_policy" "images_cloudfront_only" {
  bucket = aws_s3_bucket.images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.images.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.images.arn
          }
        }
      }
    ]
  })
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
