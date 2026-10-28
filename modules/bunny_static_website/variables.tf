variable "name" {
  description = "Name of the pull zone; also the prefix of the two storage zones (<name>-storage-a/-b)"
  type        = string
}

variable "hostname" {
  description = "Canonical hostname the site is served on, e.g. www.example.com or account.example.com"
  type        = string
}

variable "redirect_from" {
  description = "Extra hostnames that 301 to https://<hostname>, e.g. the root domain when www is canonical"
  type        = list(string)
  default     = []
}

variable "hsts" {
  description = "Strict-Transport-Security value for the custom hostnames, without the preload directive"
  type        = string
  default     = "max-age=63072000; includeSubDomains"
}

variable "hsts_preload_domain" {
  description = "Registrable domain among the site's hostnames that sends the hsts value with '; preload' appended"
  type        = string
  default     = null
}

variable "storage_region" {
  description = "Main region of the storage zones"
  type        = string
  default     = "DE"
}

variable "replication_regions" {
  description = "Regions the storage zones replicate to"
  type        = list(string)
  default     = ["SG", "NY"]
}

variable "custom_404_file_path" {
  description = "File served for missing paths"
  type        = string
  default     = "/404.html"
}

variable "immutable_paths" {
  description = "URL patterns of content-hashed files that browsers may cache for a year; everything else is revalidated"
  type        = list(string)
  default     = ["*/_astro/*"]

  validation {
    condition     = length(var.immutable_paths) > 0
    error_message = "At least one pattern is needed: the revalidate rule matches everything except these."
  }
}

variable "blocked_paths" {
  description = "URL patterns that are only ever requested by scanners and get blocked"
  type        = list(string)
  default = [
    "*.php",
    "*.env",
    "*/wp-content/*",
    "*/wp-admin/*",
    "*/cgi-bin/*",
  ]
}
