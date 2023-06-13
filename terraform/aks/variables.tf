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

locals {
  service_name = "check-childrens-barred-list"
  version      = "1.9.7"

  azure_credentials = try(jsondecode(var.azure_credentials_json), null)

  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"
}
