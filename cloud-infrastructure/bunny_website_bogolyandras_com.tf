
resource "bunnynet_storage_zone" "bogolyandras_com_storage-a" {
  name      = "bogolyandras-com-storage-a"
  region    = "DE"
  zone_tier = "Edge"

  custom_404_file_path = "/404.html"
  replication_regions  = ["SG", "NY"]
}

resource "bunnynet_storage_zone" "bogolyandras_com_storage-b" {
  name      = "bogolyandras-com-storage-b"
  region    = "DE"
  zone_tier = "Edge"

  custom_404_file_path = "/404.html"
  replication_regions  = ["SG", "NY"]
}

resource "bunnynet_pullzone" "bogolyandras_com" {
  name = "bogolyandras-com"

  origin {
    type        = "StorageZone"
    storagezone = bunnynet_storage_zone.bogolyandras_com_storage-a.id
  }

  routing {
    tier = "Standard"
  }

  lifecycle {
    # Blue/green: the website's deploy workflow switches between storage-a and storage-b,
    # so this only sets the initial zone
    ignore_changes = [origin.storagezone]
  }
}
