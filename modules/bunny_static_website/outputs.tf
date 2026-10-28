output "pullzone_id" {
  description = "ID of the pull zone"
  value       = bunnynet_pullzone.this.id
}

output "storage_zone_a_id" {
  description = "ID of the first blue/green storage zone"
  value       = bunnynet_storage_zone.a.id
}

output "storage_zone_b_id" {
  description = "ID of the second blue/green storage zone"
  value       = bunnynet_storage_zone.b.id
}

output "storage_hostname" {
  description = "Storage API endpoint for uploads; both zones share the region, so it is the same for both"
  value       = bunnynet_storage_zone.a.hostname
}

output "cdn_hostname" {
  description = "The pull zone's own b-cdn.net hostname; DNS records for the site's hostnames CNAME to it"
  value       = local.cdn_hostname
}
