CONFIG=test
ENVIRONMENT=test
CONFIG_SHORT=ts
CLUSTER_SHORT=ts
AZ_SUBSCRIPTION=s189-teacher-services-cloud-test
AZURE_RESOURCE_PREFIX=s189t01
RESOURCE_GROUP_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg
KEYVAULT_NAME=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-kv
STORAGE_ACCOUNT_NAME=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}tfstate${CONFIG_SHORT}sa
