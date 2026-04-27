# Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "images" {
  name                              = "grandma-alert-images-oac"
  description                       = "OAC for Images S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "images" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Grandma Alert Images CDN"
  default_root_object = ""

  origin {
    domain_name              = aws_s3_bucket.images.bucket_regional_domain_name
    origin_id                = "S3-Images"
    origin_access_control_id = aws_cloudfront_origin_access_control.images.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Images"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 5 # 5秒キャッシュ（監視システムなので短め）
    max_ttl     = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# Output
output "cloudfront_images_domain" {
  value       = aws_cloudfront_distribution.images.domain_name
  description = "CloudFront distribution domain for Images bucket"
}

output "cloudfront_images_distribution_id" {
  value       = aws_cloudfront_distribution.images.id
  description = "CloudFront distribution ID for Images bucket"
}
