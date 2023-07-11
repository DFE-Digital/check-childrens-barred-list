provider "azurerm" {
  features {}

  skip_provider_registration = true
  subscription_id            = try(local.azure_credentials.subscriptionId, null)
  client_id                  = try(local.azure_credentials.clientId, null)
  client_secret              = try(local.azure_credentials.clientSecret, null)
  tenant_id                  = try(local.azure_credentials.tenantId, null)
}

provider "kubernetes" {
  host                   = module.cluster_data.kubernetes_host
  client_certificate     = module.cluster_data.kubernetes_client_certificate
  client_key             = module.cluster_data.kubernetes_client_key
  cluster_ca_certificate = module.cluster_data.kubernetes_cluster_ca_certificate
}

provider "statuscake" {
  api_token = try(local.infra_secrets.STATUSCAKE_API_TOKEN, null)
}
