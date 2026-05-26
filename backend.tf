terraform {
  backend "s3" {
    bucket = "terraform-s3-slr"
    key    = "s3/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}
