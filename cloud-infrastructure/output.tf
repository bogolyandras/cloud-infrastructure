output "dnssec_key" {
  value = {
    dnssec_algorithm = bunnynet_dns_zone.cestlavie_ovh.dnssec_algorithm
    dnssec_digest = bunnynet_dns_zone.cestlavie_ovh.dnssec_digest
    dnssec_digest_type = bunnynet_dns_zone.cestlavie_ovh.dnssec_digest_type
    dnssec_flags = bunnynet_dns_zone.cestlavie_ovh.dnssec_flags
    dnssec_keytag = bunnynet_dns_zone.cestlavie_ovh.dnssec_keytag
    dnssec_public_key = bunnynet_dns_zone.cestlavie_ovh.dnssec_public_key
  }
  description = "DNSSEC stuff"
}

output "bogolyandras_com_storage-a" {
  value = {
    name = bunnynet_storage_zone.bogolyandras_com_storage-a.name
    host = bunnynet_storage_zone.bogolyandras_com_storage-a.hostname
  }
}

output "bogolyandras_com_storage-a_password" {
  value     = bunnynet_storage_zone.bogolyandras_com_storage-a.password
  sensitive = true
}

output "bogolyandras_com_storage-b" {
  value = {
    name = bunnynet_storage_zone.bogolyandras_com_storage-b.name
    host = bunnynet_storage_zone.bogolyandras_com_storage-b.hostname
  }
}

output "bogolyandras_com_storage-b_password" {
  value     = bunnynet_storage_zone.bogolyandras_com_storage-b.password
  sensitive = true
}

output "certificate_bucket_name" {
  value = module.certificate_bucket.bucket_name
}

output "certificate_access_key_id" {
  value       = aws_iam_access_key.cert.id
  description = "The access key ID for the certificate bucket IAM user"
}

output "certificate_secret_access_key" {
  value       = aws_iam_access_key.cert.secret
  description = "The secret access key for the certificate bucket IAM user"
  sensitive   = true
}
