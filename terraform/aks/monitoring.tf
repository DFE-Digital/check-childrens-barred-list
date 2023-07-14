module "statuscake" {
  count = var.enable_monitoring ? 1 : 0

  source = "git::https://github.com/DFE-Digital/terraform-modules.git//monitoring/statuscake?ref=testing"

  uptime_urls = compact([module.web_application.probe_url, var.external_url])
  ssl_urls    = compact([var.external_url])

  contact_groups = var.statuscake_contact_groups
}
