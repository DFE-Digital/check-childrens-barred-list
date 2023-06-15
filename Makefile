TERRAFILE_VERSION=0.8
ARM_TEMPLATE_TAG=1.1.0
RG_TAGS={"Product" : "Teacher services cloud"}
SERVICE_SHORT=ccbl

review:
	$(if $(APP_NAME), , $(error Missing environment variable "APP_NAME", Please specify a pr number for your review app))
	$(eval include global_config/review.sh)
	$(eval DEPLOY_ENV=review)
	$(eval export TF_VAR_app_name=$(APP_NAME))
	echo https://check-childrens-barred-list-$(APP_NAME).test.teacherservices.cloud will be created in aks

install-terrafile: ## Install terrafile to manage terraform modules
	[ ! -f bin/terrafile ] \
		&& curl -sL https://github.com/coretech/terrafile/releases/download/v${TERRAFILE_VERSION}/terrafile_${TERRAFILE_VERSION}_$$(uname)_x86_64.tar.gz \
		| tar xz -C ./bin terrafile \
		|| true

set-azure-account:
	az account set -s ${AZ_SUBSCRIPTION}

terraform-init: install-terrafile set-azure-account
	$(if $(APP_NAME), $(eval KEY_PREFIX=$(APP_NAME)), $(eval KEY_PREFIX=$(ENVIRONMENT)))
	./bin/terrafile -p terraform/aks/vendor/modules -f terraform/aks/config/$(CONFIG)_Terrafile
	terraform -chdir=terraform init -upgrade -reconfigure \
		-backend-config=resource_group_name=${RESOURCE_GROUP_NAME} \
		-backend-config=storage_account_name=${STORAGE_ACCOUNT_NAME} \
		-backend-config=key=${KEY_PREFIX}_kubernetes.tfstate

	$(eval export TF_VAR_azure_resource_prefix=$(AZURE_RESOURCE_PREFIX))
	$(eval export TF_VAR_config_short=$(CONFIG_SHORT))
	$(eval export TF_VAR_service_short=$(SERVICE_SHORT))
	$(eval export TF_VAR_rg_name=$(RESOURCE_GROUP_NAME))

terraform-plan: terraform-init
	terraform -chdir=terraform/aks plan -var-file "config/${CONFIG}.tfvars.json"

terraform-apply: terraform-init
	terraform -chdir=terraform/aks apply -var-file "config/${CONFIG}.tfvars.json"

set-what-if:
	$(eval WHAT_IF=--what-if)

arm-deployment: set-azure-account
	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "UK South" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}tfstate${CONFIG_SHORT}sa" "tfStorageContainerName=terraform-state" \
			"keyVaultName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-kv" ${WHAT_IF}

deploy-arm-resources: arm-deployment

validate-arm-resources: set-what-if arm-deployment
