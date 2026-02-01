output "dashboard_bucket_name" {
  value = aws_s3_bucket.dashboard.bucket
}

output "dashboard_bucket_arn" {
  value = aws_s3_bucket.dashboard.arn
}

output "dashboard_website_url" {
  value = "http://${aws_s3_bucket.dashboard.bucket}.s3-website-${var.region}.amazonaws.com"
}
