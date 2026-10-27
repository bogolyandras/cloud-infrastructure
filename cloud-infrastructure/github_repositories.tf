provider "github" {
  owner = "bogolyandras"
}

resource "github_repository" "cloud_infrastructure" {
  name        = "cloud-infrastructure"
  description = "OpenTofu configuration for my personal infrastructure on AWS, bunny.net and GitHub"
  visibility  = "public"

  has_issues   = true
  has_projects = false
  has_wiki     = false

  delete_branch_on_merge = true

  archive_on_destroy = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "cloud_infrastructure" {
  repository = github_repository.cloud_infrastructure.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "cloud_infrastructure" {
  repository = github_repository.cloud_infrastructure.name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.cloud_infrastructure]
}
