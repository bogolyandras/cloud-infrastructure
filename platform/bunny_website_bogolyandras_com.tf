module "bogolyandras_com" {
  source = "../modules/bunny_static_website"

  name          = "bogolyandras-com"
  hostname      = "www.bogolyandras.com"
  redirect_from = ["bogolyandras.com"]

  # Only the registrable domain may ask for preload; it then covers every subdomain
  hsts = "max-age=63072000; includeSubDomains; preload"
}
