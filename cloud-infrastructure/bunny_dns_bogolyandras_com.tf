resource "bunnynet_dns_zone" "bogolyandras_com" {
  domain = "bogolyandras.com"
  dnssec_enabled = true
  log_enabled = true
  log_anonymized = false
}

resource "bunnynet_dns_record" "bogolyandras_com_caa" {
  zone = bunnynet_dns_zone.bogolyandras_com.id

  name  = ""
  type  = "CAA"
  value = "letsencrypt.org"
  tag = "issue"
}

resource "bunnynet_dns_record" "bogolyandras_com_root" {
  zone = bunnynet_dns_zone.bogolyandras_com.id

  name  = ""
  type  = "CNAME"
  value = "bogolyandras-test.b-cdn.net"
}

resource "bunnynet_dns_record" "bogolyandras_com_www" {
  zone = bunnynet_dns_zone.bogolyandras_com.id

  name  = "www"
  type  = "CNAME"
  value = "bogolyandras-test.b-cdn.net"
}
