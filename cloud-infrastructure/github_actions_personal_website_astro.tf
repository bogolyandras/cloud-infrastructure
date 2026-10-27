# Inputs for the blue/green deploy workflow of personal-website-astro: it reads which
# storage zone the pull zone uses, uploads to the other one and switches the pull zone over

resource "github_actions_variable" "personal_website_astro_storage_endpoint" {
  repository    = github_repository.personal_website_astro.name
  variable_name = "BUNNY_STORAGE_ENDPOINT"
  value         = bunnynet_storage_zone.bogolyandras_com_storage-a.hostname
}

resource "github_actions_secret" "personal_website_astro_api_key" {
  repository  = github_repository.personal_website_astro.name
  secret_name = "BUNNY_API_KEY"
  value       = var.bunnynet_api_key
}

resource "github_actions_secret" "personal_website_astro_pull_zone_id" {
  repository  = github_repository.personal_website_astro.name
  secret_name = "BUNNY_PULL_ZONE_ID"
  value       = tostring(bunnynet_pullzone.bogolyandras_com.id)
}

resource "github_actions_secret" "personal_website_astro_storage_zone_a" {
  repository  = github_repository.personal_website_astro.name
  secret_name = "BUNNY_STORAGE_ZONE_A"
  value       = tostring(bunnynet_storage_zone.bogolyandras_com_storage-a.id)
}

resource "github_actions_secret" "personal_website_astro_storage_zone_b" {
  repository  = github_repository.personal_website_astro.name
  secret_name = "BUNNY_STORAGE_ZONE_B"
  value       = tostring(bunnynet_storage_zone.bogolyandras_com_storage-b.id)
}

# Public URL the site's contact form posts to (API Gateway in front of the contact-form Lambda)
resource "github_actions_variable" "personal_website_astro_contact_form_endpoint" {
  repository    = github_repository.personal_website_astro.name
  variable_name = "CONTACT_FORM_ENDPOINT"
  value         = "${aws_apigatewayv2_api.contact_form.api_endpoint}/contact"
}
