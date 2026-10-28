provider "aws" {
  region = "eu-west-1"
}

module "certificate_bucket" {
  source        = "../modules/s3_bucket"
  bucket_prefix = "certificate-store-"
  tags = {
    Description = "Certificate storage"
  }
}

resource "aws_iam_user" "certificate_user" {
  name = "certificate-bucket-fullaccess-user"
}

resource "aws_iam_user_policy_attachment" "certificate_user" {
  user       = aws_iam_user.certificate_user.name
  policy_arn = module.certificate_bucket.full_access_policy_arn
}

resource "aws_iam_access_key" "cert" {
  user = aws_iam_user.certificate_user.name
}
