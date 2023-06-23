variable "cluster" {}
variable "namespace" {}
variable "environment" {}
variable "azure_credentials_json" { default = null }
variable "azure_resource_prefix" {}
variable "config_short" {}
variable "service_short" {}
variable "deploy_azure_backing_services" { default = true }
variable "rg_name" {}
variable "enable_postgres_ssl" { default = true }

variable "azure_sp_credentials_json" {
  type    = string
  default = null
}

variable "key_vault_name" {}
variable "key_vault_infra_secret_name" {}
variable "key_vault_app_secret_name" {}
variable "app_name_suffix" { default = null }
variable "postgres_version" { default = 14 }
variable "app_name" { default = null }
variable "app_docker_image" {}
variable "enable_monitoring" { default = true }
variable "app_config_file" { default = "config/app_config.yml" }
variable "azure_maintenance_window" { default = null }
variable "postgres_flexible_server_sku" { default = "B_Standard_B1ms" }
variable "postgres_enable_high_availability" { default = false }
variable "startup_command" {}
variable "probe_path" { default = null }
variable "replicas" { default = 1 }
variable "memory_max" { default = "1Gi" }
variable "gov_uk_host_names" {
  default = []
  type    = list(any)
}

locals {
  service_name = "check-childrens-barred-list"
  version      = "1.9.7"

  azure_credentials = try(jsondecode(var.azure_sp_credentials_json), null)

  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"

  app_name_suffix  = var.app_name == null ? var.environment : var.app_name
  kv_app_secrets    = yamldecode(data.azurerm_key_vault_secret.app_secrets.value)
  infra_secrets     = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  app_config        = yamldecode(file(var.app_config_file))[var.environment]

  app_env_values = merge(
    local.app_config,
    #  sslmode not defined in database.yml?
    { DB_SSLMODE = local.postgres_ssl_mode }
  )

  app_resource_group_name = "${var.azure_resource_prefix}-${var.service_short}-${var.config_short}-rg"

  app_secrets = merge(
    local.kv_app_secrets,
    {
      DATABASE_URL        = module.postgres.url
    }
  )
}
