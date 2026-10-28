terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }
  required_version = ">= 1.2.0"
  backend "s3" {
    bucket = "terraform-state-bucket-20250813232413057000000001"
    key    = "bootstrap.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Create S3 bucket
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket_prefix = "terraform-state-bucket-"
  tags = {
    Name = "Terraform State Bucket"
  }
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_name" {
  value       = aws_s3_bucket.terraform_state_bucket.bucket
  description = "The name of the S3 bucket"
}
