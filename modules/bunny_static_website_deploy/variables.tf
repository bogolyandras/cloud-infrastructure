variable "repository" {
  description = "Name of the GitHub repository whose workflow deploys the site"
  type        = string
}

variable "website" {
  description = "The bunny_static_website module (or its outputs) the workflow deploys to"
  type = object({
    pullzone_id       = number
    storage_zone_a_id = number
    storage_zone_b_id = number
    storage_hostname  = string
  })
}

variable "api_key" {
  description = "bunny.net API key the workflow uses to switch the pull zone and purge its cache"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "GitHub environment that holds the secrets"
  type        = string
  default     = "production"
}

variable "branch" {
  description = "The only branch whose jobs may use the environment"
  type        = string
  default     = "main"
}
