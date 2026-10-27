locals {
  website_root_domain = "bogolyandras.com"
  website_www_domain  = "www.${local.website_root_domain}"

  # cdn_domain is only the shared suffix (b-cdn.net); the zone's own host is prefixed with its name
  website_cdn_hostname = "${bunnynet_pullzone.bogolyandras_com.name}.${bunnynet_pullzone.bogolyandras_com.cdn_domain}"
}

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

  cors_enabled         = false
  log_anonymized       = false
  errorpage_whitelabel = true

  # TLS 1.2 and 1.3 are always on; tls_support lists the older versions also accepted
  tls_level   = "Compatible"
  tls_support = ["TLSv1.1"]

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

# Redirects to https and www are done by the edge rules below, so force_ssl stays off
resource "bunnynet_pullzone_hostname" "bogolyandras_com_root" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  name        = local.website_root_domain
  tls_enabled = true
  force_ssl   = false
}

resource "bunnynet_pullzone_hostname" "bogolyandras_com_www" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  name        = local.website_www_domain
  tls_enabled = true
  force_ssl   = false
}

resource "bunnynet_pullzone_edgerule" "bogolyandras_com_block_bots" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  description = "Stop stupid bots"
  enabled     = true

  # Static site: requests for PHP, dotenv or WordPress/CGI paths are only ever scanners
  actions = [{
    type       = "BlockRequest"
    parameter1 = null
    parameter2 = null
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns = [
      "*.php",
      "*.env",
      "*/wp-content/*",
      "*/wp-admin/*",
      "*/cgi-bin/*",
    ]
    parameter1 = null
    parameter2 = null
  }]
}

resource "bunnynet_pullzone_edgerule" "bogolyandras_com_redirect_to_www" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  description = "Redirect if not HTTPS or for www subdomain"
  enabled     = true

  # Only redirect to the custom domains once they are attached to this zone
  depends_on = [
    bunnynet_pullzone_hostname.bogolyandras_com_root,
    bunnynet_pullzone_hostname.bogolyandras_com_www,
  ]

  actions = [{
    type       = "Redirect"
    parameter1 = "https://${local.website_www_domain}{{path}}"
    parameter2 = "301"
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns = [
      "*://${local.website_cdn_hostname}*",
      "https://${local.website_root_domain}*",
      "http://${local.website_www_domain}*",
    ]
    parameter1 = null
    parameter2 = null
  }]
}

# HSTS preload requires HTTP to redirect to HTTPS on the same host first, so the
# root domain goes http -> https here and only then to www via the rule above
resource "bunnynet_pullzone_edgerule" "bogolyandras_com_redirect_root_to_https" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  description = "Redirect if not HTTPS for main domain"
  enabled     = true

  # Only redirect to the custom domains once they are attached to this zone
  depends_on = [
    bunnynet_pullzone_hostname.bogolyandras_com_root,
    bunnynet_pullzone_hostname.bogolyandras_com_www,
  ]

  actions = [{
    type       = "Redirect"
    parameter1 = "https://${local.website_root_domain}{{path}}"
    parameter2 = "301"
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns   = ["http://${local.website_root_domain}*"]
    parameter1 = null
    parameter2 = null
  }]
}

resource "bunnynet_pullzone_edgerule" "bogolyandras_com_hsts" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  description = "HTST Header"
  enabled     = true

  # Only redirect to the custom domains once they are attached to this zone
  depends_on = [
    bunnynet_pullzone_hostname.bogolyandras_com_root,
    bunnynet_pullzone_hostname.bogolyandras_com_www,
  ]

  actions = [{
    type       = "SetResponseHeader"
    parameter1 = "Strict-Transport-Security"
    parameter2 = "max-age=63072000; includeSubDomains; preload"
    parameter3 = null
  }]

  # GET request to either custom domain over HTTPS
  match_type = "MatchAll"
  triggers = [
    {
      type       = "RequestMethod"
      match_type = "MatchAny"
      patterns   = ["GET"]
      parameter1 = null
      parameter2 = null
    },
    {
      type       = "Url"
      match_type = "MatchAny"
      patterns = [
        "https://${local.website_root_domain}*",
        "https://${local.website_www_domain}*",
      ]
      parameter1 = null
      parameter2 = null
    },
  ]
}

resource "bunnynet_pullzone_edgerule" "bogolyandras_com_txt_content_type" {
  pullzone    = bunnynet_pullzone.bogolyandras_com.id
  description = "UTF-8 content type for text files"
  enabled     = true

  actions = [{
    type       = "SetResponseHeader"
    parameter1 = "Content-Type"
    parameter2 = "text/plain; charset=utf-8"
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns   = ["*.txt"]
    parameter1 = null
    parameter2 = null
  }]
}
