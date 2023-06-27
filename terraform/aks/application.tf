module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = true

  namespace    = var.namespace
  environment  = local.app_name_suffix
  service_name = local.service_name

  cluster_configuration_map = module.cluster_data.configuration_map

  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image  = var.app_docker_image
  command       = var.startup_command
  max_memory    = var.memory_max
  replicas      = var.replicas
  probe_path    = var.probe_path

  web_external_hostnames = var.gov_uk_host_names
}

module "application_configuration" {

  source = "./vendor/modules/aks//aks/application_configuration"

  namespace             = var.namespace
  environment           = local.app_name_suffix
  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  config_short          = var.config_short
  config_variables      = local.app_env_values
  secret_variables      = local.app_secrets
  secret_yaml_key       = var.key_vault_app_secret_name
}
