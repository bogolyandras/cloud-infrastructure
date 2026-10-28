locals {
  # cdn_domain is only the shared suffix (b-cdn.net); the zone's own host is prefixed with its name
  cdn_hostname = "${bunnynet_pullzone.this.name}.${bunnynet_pullzone.this.cdn_domain}"

  all_hostnames = concat(var.redirect_from, [var.hostname])
}

# Two storage zones for blue/green deploys: the site's deploy workflow uploads to the one
# the pull zone is not using and then switches the pull zone over
resource "bunnynet_storage_zone" "a" {
  name      = "${var.name}-storage-a"
  region    = var.storage_region
  zone_tier = "Edge"

  custom_404_file_path = var.custom_404_file_path
  replication_regions  = var.replication_regions
}

resource "bunnynet_storage_zone" "b" {
  name      = "${var.name}-storage-b"
  region    = var.storage_region
  zone_tier = "Edge"

  custom_404_file_path = var.custom_404_file_path
  replication_regions  = var.replication_regions
}

resource "bunnynet_pullzone" "this" {
  name = var.name

  cors_enabled         = false
  log_anonymized       = false
  errorpage_whitelabel = true

  # TLS 1.2 and 1.3 are always on; tls_support lists the older versions also accepted
  tls_level   = "Compatible"
  tls_support = ["TLSv1.1"]

  origin {
    type        = "StorageZone"
    storagezone = bunnynet_storage_zone.a.id
  }

  routing {
    tier = "Standard"
  }

  lifecycle {
    # Blue/green: the deploy workflow switches between storage-a and storage-b,
    # so this only sets the initial zone
    ignore_changes = [origin.storagezone]
  }
}

# force_ssl redirects http to https on the same host. HSTS preload requires that step
# before any redirect to another host, so redirect_from hosts go http -> https -> hostname
resource "bunnynet_pullzone_hostname" "this" {
  for_each = toset(local.all_hostnames)

  pullzone    = bunnynet_pullzone.this.id
  name        = each.value
  tls_enabled = true
  force_ssl   = true
}

resource "bunnynet_pullzone_edgerule" "block_bots" {
  pullzone    = bunnynet_pullzone.this.id
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
    patterns   = var.blocked_paths
    parameter1 = null
    parameter2 = null
  }]
}

# The b-cdn.net hostname always exists, so this rule is there even without redirect_from
resource "bunnynet_pullzone_edgerule" "redirect_to_hostname" {
  pullzone    = bunnynet_pullzone.this.id
  description = "Redirect to ${var.hostname}"
  enabled     = true

  # Only redirect to the custom domains once they are attached to this zone
  depends_on = [bunnynet_pullzone_hostname.this]

  actions = [{
    type       = "Redirect"
    parameter1 = "https://${var.hostname}{{path}}"
    parameter2 = "301"
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns = concat(
      ["*://${local.cdn_hostname}*"],
      [for h in var.redirect_from : "https://${h}*"],
    )
    parameter1 = null
    parameter2 = null
  }]
}

# Sent on every custom hostname, including the redirect_from ones: HSTS preload requires
# the header on the registrable domain's redirect too
resource "bunnynet_pullzone_edgerule" "hsts" {
  pullzone    = bunnynet_pullzone.this.id
  description = "HSTS header"
  enabled     = true

  depends_on = [bunnynet_pullzone_hostname.this]

  actions = [{
    type       = "SetResponseHeader"
    parameter1 = "Strict-Transport-Security"
    parameter2 = var.hsts
    parameter3 = null
  }]

  # GET request to a custom hostname over HTTPS
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
      patterns   = [for h in local.all_hostnames : "https://${h}*"]
      parameter1 = null
      parameter2 = null
    },
  ]
}

resource "bunnynet_pullzone_edgerule" "txt_content_type" {
  pullzone    = bunnynet_pullzone.this.id
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

# The storage zone answers with a ~300 day max-age, so browsers kept serving old pages
# until a hard refresh. The edge cache keeps that long lifetime (the deploy purges it);
# only the header sent to browsers is replaced here.

# Unhashed files (HTML, favicons, sitemaps) are revalidated on every load; the ETag turns
# an unchanged file into a 304 without a body
resource "bunnynet_pullzone_edgerule" "cache_revalidate" {
  pullzone    = bunnynet_pullzone.this.id
  description = "Browsers revalidate unhashed files"
  enabled     = true

  actions = [{
    type       = "SetResponseHeader"
    parameter1 = "Cache-Control"
    parameter2 = "no-cache"
    parameter3 = null
  }]

  # Excludes immutable_paths instead of relying on rule order against the rule below
  match_type = "MatchAll"
  triggers = [{
    type       = "Url"
    match_type = "MatchNone"
    patterns   = var.immutable_paths
    parameter1 = null
    parameter2 = null
  }]
}

# Content-hashed files (Astro's /_astro/ by default) get a new URL whenever they change,
# so the old one can be kept forever
resource "bunnynet_pullzone_edgerule" "cache_immutable" {
  pullzone    = bunnynet_pullzone.this.id
  description = "Browsers keep hashed assets for a year"
  enabled     = true

  actions = [{
    type       = "SetResponseHeader"
    parameter1 = "Cache-Control"
    parameter2 = "public, max-age=31536000, immutable"
    parameter3 = null
  }]

  match_type = "MatchAny"
  triggers = [{
    type       = "Url"
    match_type = "MatchAny"
    patterns   = var.immutable_paths
    parameter1 = null
    parameter2 = null
  }]
}
