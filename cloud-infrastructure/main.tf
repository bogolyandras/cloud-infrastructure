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
  }
  backend "s3" {
    bucket     = "terraform-state-bucket-20250813232413057000000001"
    key        = "bunny.tfstate"
    region     = "eu-west-1"
  }
}

resource "bunnynet_storage_zone" "bogolyandras_com_storage" {
  name      = "bogolyandras-com-storage"
  region    = "DE"
  zone_tier = "Edge"

  custom_404_file_path = "/404.html"
  replication_regions = ["SG", "NY"]
}

resource "bunnynet_storage_zone" "bogolyandras_com_storage-a" {
  name      = "bogolyandras-com-storage-a"
  region    = "DE"
  zone_tier = "Edge"

  custom_404_file_path = "/404.html"
  replication_regions = ["SG", "NY"]
}

resource "bunnynet_storage_zone" "bogolyandras_com_storage-b" {
  name      = "bogolyandras-com-storage-b"
  region    = "DE"
  zone_tier = "Edge"

  custom_404_file_path = "/404.html"
  replication_regions = ["SG", "NY"]
}
