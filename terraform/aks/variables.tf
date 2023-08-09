variable "app_config_file" {
  type    = string
  default = "config/app_config.yml"
}

variable "app_docker_image" {
  type = string
}

variable "app_name" {
  type    = string
  default = null
}

variable "app_name_suffix" {
  type    = string
  default = null
}

variable "azure_credentials_json" {
  type    = string
  default = null
}

variable "azure_maintenance_window" {
  type    = map
  default = null
}

variable "azure_resource_prefix" {
  type = string
}

variable "azure_sp_credentials_json" {
  type    = string
  default = null
}

variable "cluster" {
  type = string
}

variable "config_short" {
  type = string
}

variable "deploy_azure_backing_services" {
  type    = bool
  default = true
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "enable_postgres_ssl" {
  type    = bool
  default = true
}

variable "environment" {
  type = string
}

variable "external_url" {
  type    = string
  default = null
}

variable "gov_uk_host_names" {
  default = []
  type    = list(any)
}

variable "key_vault_app_secret_name" {
  type = string
}

variable "key_vault_infra_secret_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "memory_max" {
  type    = string
  default = "1Gi"
}

variable "namespace" {
  type = string
}

variable "postgres_enable_high_availability" {
  type    = string
  default = false
}

variable "postgres_flexible_server_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "postgres_version" {
  type    = number
  default = 14
}

variable "probe_path" {
  type    = string
  default = null
}

variable "replicas" {
  type    = number
  default = 1
}

variable "rg_name" {
  type = string
}

variable "service_short" {
  type = string
}

variable "startup_command" {
  type = list(string)
}

variable "statuscake_contact_groups" {
  type    = list(number)
  default = []
}

locals {
  service_name = "check-childrens-barred-list"
  version      = "1.9.7"

  azure_credentials = try(jsondecode(var.azure_sp_credentials_json), null)

  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"

  app_name_suffix = var.app_name == null ? var.environment : var.app_name
  kv_app_secrets  = yamldecode(data.azurerm_key_vault_secret.app_secrets.value)
  infra_secrets   = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  app_config      = yamldecode(file(var.app_config_file))[var.environment]

  app_env_values = merge(
    local.app_config,
    {
      DB_SSLMODE = local.postgres_ssl_mode
      BIGQUERY_PROJECT_ID = "teaching-qualifications",
      BIGQUERY_DATASET    = "events_${var.environment}",
      BIGQUERY_TABLE_NAME = "events",
    }
  )

  app_resource_group_name = "${var.azure_resource_prefix}-${var.service_short}-${var.config_short}-rg"

  app_secrets = merge(
    local.kv_app_secrets,
    {
      DATABASE_URL = module.postgres.url
    }
  )
}
