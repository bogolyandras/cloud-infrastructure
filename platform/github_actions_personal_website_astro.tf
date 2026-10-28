# Inputs for the blue/green deploy workflow of personal-website-astro: it reads which
# storage zone the pull zone uses, uploads to the other one and switches the pull zone over

# Secrets live in this environment so only jobs running on main can read them;
# runs from other branches, pull requests or workflow_dispatch elsewhere are refused
resource "github_repository_environment" "personal_website_astro_production" {
  repository  = github_repository.personal_website_astro.name
  environment = "production"

  # Otherwise admins (the repo owner) would bypass the branch restriction
  can_admins_bypass = false

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "personal_website_astro_production_main" {
  repository     = github_repository.personal_website_astro.name
  environment    = github_repository_environment.personal_website_astro_production.environment
  branch_pattern = "main"
}

resource "github_actions_variable" "personal_website_astro_storage_endpoint" {
  repository    = github_repository.personal_website_astro.name
  variable_name = "BUNNY_STORAGE_ENDPOINT"
  value         = module.bogolyandras_com.storage_hostname
}

# Public URL the site's contact form posts to (API Gateway in front of the contact-form Lambda)
resource "github_actions_variable" "personal_website_astro_contact_form_endpoint" {
  repository    = github_repository.personal_website_astro.name
  variable_name = "CONTACT_FORM_ENDPOINT"
  value         = "${aws_apigatewayv2_api.contact_form.api_endpoint}/contact"
}

resource "github_actions_environment_secret" "personal_website_astro_api_key" {
  repository  = github_repository.personal_website_astro.name
  environment = github_repository_environment.personal_website_astro_production.environment
  secret_name = "BUNNY_API_KEY"
  value       = var.bunnynet_api_key
}

resource "github_actions_environment_secret" "personal_website_astro_pull_zone_id" {
  repository  = github_repository.personal_website_astro.name
  environment = github_repository_environment.personal_website_astro_production.environment
  secret_name = "BUNNY_PULL_ZONE_ID"
  value       = tostring(module.bogolyandras_com.pullzone_id)
}

resource "github_actions_environment_secret" "personal_website_astro_storage_zone_a" {
  repository  = github_repository.personal_website_astro.name
  environment = github_repository_environment.personal_website_astro_production.environment
  secret_name = "BUNNY_STORAGE_ZONE_A"
  value       = tostring(module.bogolyandras_com.storage_zone_a_id)
}

resource "github_actions_environment_secret" "personal_website_astro_storage_zone_b" {
  repository  = github_repository.personal_website_astro.name
  environment = github_repository_environment.personal_website_astro_production.environment
  secret_name = "BUNNY_STORAGE_ZONE_B"
  value       = tostring(module.bogolyandras_com.storage_zone_b_id)
}
