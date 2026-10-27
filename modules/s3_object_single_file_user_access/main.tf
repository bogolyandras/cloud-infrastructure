resource "aws_iam_user" "this" {
  name = var.user_name
  tags = merge({
    CreatedBy = "Terraform"
    Purpose   = "S3 object-scoped access"
  }, var.tags)
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

# Policy granting minimal bucket permissions and object-level access to a single key
resource "aws_iam_policy" "this" {
  name        = "${var.user_name}-s3-object-access"
  description = "Allows minimal S3 bucket operations and access to a single object ${var.object_key} in bucket ${var.bucket_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}"
        Condition = {
          StringLike = {
            # Limit listing to the exact object key so the user cannot list other prefixes
            "s3:prefix" : [
              var.object_key
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/${var.object_key}"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "this" {
  user       = aws_iam_user.this.name
  policy_arn = aws_iam_policy.this.arn
}
