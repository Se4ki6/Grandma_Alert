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
