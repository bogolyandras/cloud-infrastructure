resource "bunnynet_dns_zone" "cestlavie_ovh" {
  domain = "cestlavie.ovh"
  dnssec_enabled = true
  log_enabled = true
  log_anonymized = false
}

resource "bunnynet_dns_record" "cestlavie_ovh_caa" {
  zone = bunnynet_dns_zone.cestlavie_ovh.id

  name  = ""
  type  = "CAA"
  value = "letsencrypt.org"
  tag = "issue"
}
