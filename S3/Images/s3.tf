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
      filter_suffix       = lambda_function.value  # ここでリストの値が参照される
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
