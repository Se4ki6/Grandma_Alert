output "dashboard_bucket_name" {
  value = aws_s3_bucket.dashboard.bucket
}

output "dashboard_bucket_arn" {
  value = aws_s3_bucket.dashboard.arn
}

output "dashboard_website_url" {
  value       = "http://${aws_s3_bucket.dashboard.bucket}.s3-website-${var.region}.amazonaws.com"
  description = "S3 Website URL (deprecated - use CloudFront URL)"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.dashboard.id
  description = "CloudFront Distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.dashboard.domain_name
  description = "CloudFront Distribution Domain Name"
}

output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.dashboard.arn
  description = "CloudFront Distribution ARN"
}
