terraform {
  required_providers {
    bunnynet = {
      source  = "BunnyWay/bunnynet"
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
    bucket = "terraform-state-bucket-20250813232413057000000001"
    key    = "platform.tfstate"
    region = "eu-west-1"
  }
}

# Passed in as a variable (TF_VAR_bunnynet_api_key) so it can also be handed to the website's deploy workflow
variable "bunnynet_api_key" {
  type      = string
  sensitive = true
}

provider "bunnynet" {
  api_key = var.bunnynet_api_key
}
