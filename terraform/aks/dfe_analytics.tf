provider "google" {
  project = "teaching-qualifications"
}

module "dfe_analytics" {
  count = var.enable_dfe_analytics_federated_auth ? 1 : 0
  source = "./vendor/modules/aks//aks/dfe_analytics"

  azure_resource_prefix = var.azure_resource_prefix
  cluster               = var.cluster
  namespace             = var.namespace
  service_short         = var.service_short
  environment           = local.app_name_suffix
  gcp_dataset           = var.gcp_dataset_name != null ? var.gcp_dataset_name  : "ccbl_events_${var.config}"
}
