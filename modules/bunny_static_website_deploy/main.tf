# Inputs for a blue/green deploy workflow: it reads which storage zone the pull zone
# uses, uploads to the other one and switches the pull zone over

# Secrets live in this environment so only jobs running on the branch can read them;
# runs from other branches, pull requests or workflow_dispatch elsewhere are refused
resource "github_repository_environment" "this" {
  repository  = var.repository
  environment = var.environment

  # Otherwise admins (the repo owner) would bypass the branch restriction
  can_admins_bypass = false

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "branch" {
  repository     = var.repository
  environment    = github_repository_environment.this.environment
  branch_pattern = var.branch
}

resource "github_actions_variable" "storage_endpoint" {
  repository    = var.repository
  variable_name = "BUNNY_STORAGE_ENDPOINT"
  value         = var.website.storage_hostname
}

resource "github_actions_environment_secret" "api_key" {
  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = "BUNNY_API_KEY"
  value       = var.api_key
}

resource "github_actions_environment_secret" "pull_zone_id" {
  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = "BUNNY_PULL_ZONE_ID"
  value       = tostring(var.website.pullzone_id)
}

resource "github_actions_environment_secret" "storage_zone_a" {
  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = "BUNNY_STORAGE_ZONE_A"
  value       = tostring(var.website.storage_zone_a_id)
}

resource "github_actions_environment_secret" "storage_zone_b" {
  repository  = var.repository
  environment = github_repository_environment.this.environment
  secret_name = "BUNNY_STORAGE_ZONE_B"
  value       = tostring(var.website.storage_zone_b_id)
}
