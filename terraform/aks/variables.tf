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

variable "enable_logit" { default = false }

variable "enable_dfe_analytics_federated_auth" {
  description = "Create the resources in Google cloud for federated authentication and enable in application"
  default     = false
}

variable "config" {
  description = "Long name of the environment configuration, e.g. development, staging, production..."
}

variable "gcp_dataset_name" {
  description = "Name of the GCP dataset used by Bigquery for an environment. If null will use ccbl_events_{var.config} "
  type    = string
  default = null
}

locals {
  service_name = "check-childrens-barred-list"
  version      = "1.9.7"


  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"

  app_name_suffix = var.app_name == null ? var.environment : var.app_name
  kv_app_secrets  = yamldecode(data.azurerm_key_vault_secret.app_secrets.value)
  infra_secrets   = yamldecode(data.azurerm_key_vault_secret.infra_secrets.value)
  app_config      = yamldecode(file(var.app_config_file))[var.environment]

  app_env_values = merge(
    local.app_config,
    {
      BIGQUERY_PROJECT_ID = "teaching-qualifications",
      BIGQUERY_DATASET    = var.environment == "preproduction" ? "ccbl_events_preprod" : "ccbl_events_${var.environment}",
      BIGQUERY_TABLE_NAME = "events",
      DB_SSLMODE = local.postgres_ssl_mode,
      HOSTING_ENVIRONMENT = var.environment,
    }
  )

  app_resource_group_name = "${var.azure_resource_prefix}-${var.service_short}-${var.config_short}-rg"

  app_secrets = merge(
    local.kv_app_secrets,
    {
      DATABASE_URL = module.postgres.url,
      REDIS_URL    = module.redis.url,
      GOOGLE_CLOUD_CREDENTIALS = var.enable_dfe_analytics_federated_auth ? module.dfe_analytics[0].google_cloud_credentials : null
    }
  )
}
