module "bogolyandras_com_deploy" {
  source = "../modules/bunny_static_website_deploy"

  repository = github_repository.personal_website_astro.name
  website    = module.bogolyandras_com
  api_key    = var.bunnynet_api_key
}

# Public URL the site's contact form posts to (API Gateway in front of the contact-form Lambda)
resource "github_actions_variable" "personal_website_astro_contact_form_endpoint" {
  repository    = github_repository.personal_website_astro.name
  variable_name = "CONTACT_FORM_ENDPOINT"
  value         = "${aws_apigatewayv2_api.contact_form.api_endpoint}/contact"
}
