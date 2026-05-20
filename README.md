# AWS S3 Terraform Module with GitHub Actions

This repository contains a comprehensive, reusable Terraform module for creating and managing AWS S3 buckets with best practices for security, lifecycle management, and automation via GitHub Actions.

## Features

### 🔐 Security Best Practices
- **Server-side encryption** with AES256 or AWS KMS
- **Public access blocking** by default
- **Bucket versioning** enabled by default
- **Access logging** support
- **Bucket policies** for fine-grained access control

### 🔄 Lifecycle Management
- **Intelligent tiering** with customizable lifecycle rules
- **Automatic cleanup** of old versions
- **Cost optimization** through storage class transitions

### 🌐 Website Hosting
- **Static website hosting** configuration
- **CORS rules** for cross-origin requests
- **Custom error pages** support

### 📧 Event Notifications
- **Lambda function** triggers
- **SNS topic** notifications
- **SQS queue** integration

### 🚀 CI/CD Integration
- **GitHub Actions** workflow for automated deployment
- **Terraform plan/apply/destroy** operations
- **Pull request** integration with plan comments

## Module Structure

```
modules/s3/
├── main.tf          # Main S3 resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── versions.tf      # Provider requirements
```

## Usage Examples

### Basic S3 Bucket

```hcl
module "basic_s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-basic-bucket-unique-suffix"

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
```

### Advanced S3 Bucket with Lifecycle Rules

```hcl
module "advanced_s3_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-advanced-bucket-unique-suffix"
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
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "advanced-example"
  }
}
```

### Static Website Hosting

```hcl
module "website_s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-website-bucket-unique-suffix"

  # Disable public access blocks for website hosting
  # IMPORTANT: These must be set to false BEFORE applying a public bucket policy
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
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-website-bucket-unique-suffix/*"
      }
    ]
  })
}
```

> **Note**: The module automatically handles the timing issue between public access block settings and bucket policies by adding a delay resource. This ensures public access blocks are updated before applying public policies.

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | The name of the S3 bucket | `string` | n/a | yes |
| `versioning_enabled` | Enable versioning for the S3 bucket | `bool` | `true` | no |
| `sse_algorithm` | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| `kms_master_key_id` | KMS key ID for SSE-KMS encryption | `string` | `null` | no |
| `force_destroy` | Allow destruction of non-empty bucket | `bool` | `false` | no |
| `block_public_acls` | Block public ACLs | `bool` | `true` | no |
| `block_public_policy` | Block public bucket policies | `bool` | `true` | no |
| `ignore_public_acls` | Ignore public ACLs | `bool` | `true` | no |
| `restrict_public_buckets` | Restrict public bucket policies | `bool` | `true` | no |
| `lifecycle_rules` | List of lifecycle rules | `list(object)` | `[]` | no |
| `cors_rules` | List of CORS rules | `list(object)` | `[]` | no |
| `website_config` | Website hosting configuration | `object` | `null` | no |
| `bucket_policy` | JSON bucket policy | `string` | `null` | no |
| `notification_config` | Event notification configuration | `object` | `null` | no |
| `logging_config` | Access logging configuration | `object` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | The ID of the S3 bucket |
| `bucket_arn` | The ARN of the S3 bucket |
| `bucket_domain_name` | The bucket domain name |
| `bucket_regional_domain_name` | The bucket region-specific domain name |
| `bucket_hosted_zone_id` | The Route 53 Hosted Zone ID |
| `bucket_region` | The AWS region of the bucket |
| `bucket_website_endpoint` | The website endpoint (if configured) |
| `bucket_website_domain` | The website domain (if configured) |

## GitHub Actions Workflow

The repository includes a comprehensive GitHub Actions workflow that supports:

- **Terraform Plan** on pull requests
- **Terraform Apply** on main branch pushes
- **Manual Terraform Destroy** via workflow dispatch
- **PR Comments** with plan output
- **Multi-environment** support

### Workflow Triggers

1. **Pull Request**: Runs `terraform plan` and comments results
2. **Push to Main**: Runs `terraform apply` 
3. **Manual Dispatch**: Choose between plan, apply, or destroy

### Required Secrets

Set up the following in your GitHub repository secrets:

- `AWS_ROLE_ARN`: IAM role for GitHub Actions (configured for OIDC)
- `AWS_REGION`: AWS region (default: ap-south-1)

## Prerequisites

- **Terraform** >= 1.0
- **AWS Provider** >= 5.0
- **AWS CLI** configured with appropriate permissions
- **GitHub repository** with Actions enabled

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd githubactions-terraform-s3
   ```

2. **Update the bucket names** in `main.tf` to be globally unique

3. **Configure AWS credentials** for local development:
   ```bash
   aws configure
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan the deployment**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Troubleshooting

### Public Bucket Policy Errors

If you encounter errors like:
```
api error AccessDenied: User is not authorized to perform: s3:PutBucketPolicy because public policies are blocked by the BlockPublicPolicy
```

**Solution**: The module now automatically handles this by:
1. Configuring public access block settings first
2. Adding a time delay to ensure settings take effect
3. Then applying the bucket policy

If you still encounter issues:
1. Ensure all public access block variables are set to `false` for public buckets
2. Run `terraform apply` again - the delay should resolve timing issues
3. For manual troubleshooting, you can disable public access blocks first, then apply the policy in a separate run

## Best Practices Implemented

### Security
- ✅ Server-side encryption enabled by default
- ✅ Public access blocked by default
- ✅ Versioning enabled for data protection
- ✅ Access logging support
- ✅ IAM roles with least privilege

### Cost Optimization
- ✅ Lifecycle rules for automatic tiering
- ✅ Old version cleanup
- ✅ Intelligent tiering options

### Operational Excellence
- ✅ Comprehensive tagging strategy
- ✅ Automated CI/CD pipeline
- ✅ Infrastructure as Code
- ✅ Plan review process via PRs

### Reliability
- ✅ Multi-AZ by default (S3 feature)
- ✅ Versioning for data recovery
- ✅ Cross-region replication support (configurable)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

The GitHub Actions workflow will automatically run `terraform plan` and comment the results on your PR.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions or issues, please open a GitHub issue or contact the maintainers.
