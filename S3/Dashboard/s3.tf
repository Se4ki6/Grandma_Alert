// ---------------------------------------------
// S3: Dashboard bucket (public website)
// ---------------------------------------------
resource "aws_s3_bucket" "dashboard" {
  bucket = var.dashboard_bucket_name

  tags = merge(
    var.tags,
    {
      Name = "Dashboard Bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket                  = aws_s3_bucket.dashboard.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dashboard_public" {
  bucket = aws_s3_bucket.dashboard.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForGetBucketObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.dashboard.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

// ---------------------------------------------
// S3: Upload files to dashboard bucket
// ---------------------------------------------
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.dashboard.id
  key          = "index.html"
  source       = "${path.module}/upload_file/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/upload_file/index.html")

  depends_on = [
    aws_s3_bucket_public_access_block.dashboard,
    aws_s3_bucket_policy.dashboard_public
  ]
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.dashboard.id
  key          = "error.html"
  source       = "${path.module}/upload_file/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/upload_file/error.html")

  depends_on = [
    aws_s3_bucket_public_access_block.dashboard,
    aws_s3_bucket_policy.dashboard_public
  ]
}
