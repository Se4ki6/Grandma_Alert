output "images_bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "images_bucket_arn" {
  value = aws_s3_bucket.images.arn
}

output "images_bucket_domain_name" {
  value       = aws_s3_bucket.images.bucket_regional_domain_name
  description = "S3バケットのリージョナルドメイン名"
}

output "images_bucket_url" {
  value       = "https://${aws_s3_bucket.images.bucket_regional_domain_name}"
  description = "S3バケットの直接アクセスURL"
}
