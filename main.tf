terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Example 1: Basic S3 bucket
module "basic_s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-basic-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

# Example 2: S3 bucket with advanced features
module "advanced_s3_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-advanced-bucket-${random_id.bucket_suffix.hex}"
  versioning_enabled = true
  sse_algorithm      = "AES256"

  lifecycle_rules = [
    {
      id     = "transition_to_ia"
      status = "Enabled"
      filter = {
        prefix = "documents/"
      }
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    },
    {
      id     = "delete_old_versions"
      status = "Enabled"
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
    }
  ]

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "POST", "PUT"]
      allowed_origins = ["https://example.com"]
      max_age_seconds = 3000
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "advanced-example"
    Owner       = "team-a"
  }
}

# Example 3: S3 bucket for static website hosting
module "website_s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-website-bucket-${random_id.bucket_suffix.hex}"

  # Disable public access blocks for website hosting
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  website_config = {
    index_document = "index.html"
    error_document = "error.html"
  }

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-website-bucket-${random_id.bucket_suffix.hex}/*"
      }
    ]
  })

  tags = {
    Environment = "prod"
    Project     = "website"
    Type        = "static-website"
  }
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Outputs
output "basic_bucket_info" {
  description = "Basic S3 bucket information"
  value = {
    id                        = module.basic_s3_bucket.bucket_id
    arn                       = module.basic_s3_bucket.bucket_arn
    domain_name               = module.basic_s3_bucket.bucket_domain_name
    regional_domain_name      = module.basic_s3_bucket.bucket_regional_domain_name
  }
}

output "advanced_bucket_info" {
  description = "Advanced S3 bucket information"
  value = {
    id                        = module.advanced_s3_bucket.bucket_id
    arn                       = module.advanced_s3_bucket.bucket_arn
    domain_name               = module.advanced_s3_bucket.bucket_domain_name
    regional_domain_name      = module.advanced_s3_bucket.bucket_regional_domain_name
  }
}

output "website_bucket_info" {
  description = "Website S3 bucket information"
  value = {
    id                        = module.website_s3_bucket.bucket_id
    arn                       = module.website_s3_bucket.bucket_arn
    website_endpoint          = module.website_s3_bucket.bucket_website_endpoint
    website_domain            = module.website_s3_bucket.bucket_website_domain
  }
}