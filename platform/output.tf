output "dnssec_key" {
  value = {
    dnssec_algorithm   = bunnynet_dns_zone.cestlavie_ovh.dnssec_algorithm
    dnssec_digest      = bunnynet_dns_zone.cestlavie_ovh.dnssec_digest
    dnssec_digest_type = bunnynet_dns_zone.cestlavie_ovh.dnssec_digest_type
    dnssec_flags       = bunnynet_dns_zone.cestlavie_ovh.dnssec_flags
    dnssec_keytag      = bunnynet_dns_zone.cestlavie_ovh.dnssec_keytag
    dnssec_public_key  = bunnynet_dns_zone.cestlavie_ovh.dnssec_public_key
  }
  description = "DNSSEC for cestlavie.ovh"
}

output "contact_form_api_endpoint" {
  value = aws_apigatewayv2_api.contact_form.api_endpoint
}

output "certificate_bucket_name" {
  value = {
    name       = module.certificate_bucket.bucket_name,
    key_id     = aws_iam_access_key.cert.id
    key_secret = aws_iam_access_key.cert.secret
  }
  sensitive = true
}
