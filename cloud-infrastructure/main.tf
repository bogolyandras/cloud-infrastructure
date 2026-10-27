terraform {
  required_providers {
    bunnynet = {
      source = "BunnyWay/bunnynet"
      version = "~> 0.19"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
  backend "s3" {
    bucket     = "terraform-state-bucket-20250813232413057000000001"
    key        = "bunny.tfstate"
    region     = "eu-west-1"
  }
}
