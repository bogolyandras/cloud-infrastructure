module "bogolyandras_com" {
  source = "../modules/bunny_static_website"

  name          = "bogolyandras-com"
  hostname      = "www.bogolyandras.com"
  redirect_from = ["bogolyandras.com"]

  # The preload list entry for the registrable domain covers every subdomain
  hsts_preload_domain = "bogolyandras.com"
}
