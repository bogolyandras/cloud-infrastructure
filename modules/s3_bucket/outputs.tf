
output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN for the s3 bucket"
  value       = aws_s3_bucket.this.arn
}


output "full_access_policy_arn" {
  description = "ARN for the full access policy for this bucket"
  value       = aws_iam_policy.full_access_policy.arn
}
