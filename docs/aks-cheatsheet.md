# Azure Kubernetes Service / AKS cheatsheet

Requirements

Azure CIP account and access to the s189 subscription

- <https://technical-guidance.education.gov.uk/infrastructure/hosting/azure-cip/#onboarding-users>
- request s189 access from the devops team

azure-cli installed locally

- see <https://technical-guidance.education.gov.uk/infrastructure/dev-tools/#azure-cli>

kubectl installed locally

- see <https://github.com/DFE-Digital/teacher-services-cloud#kubectl>

All examples below show qa usage and you should adapt accordingly.

## Cluster and app info

There are several AKS clusters, but only 2 are relevant for this service.

s189t01-tsc-test-aks

- in s189-teacher-services-cloud-test subscription
- in s189t01-tsc-ts-rg resource group
- contains tra-development and tra-test namespaces
- will hold review and non-prod envs
- PIM self approval required

s189p01-tsc-production-aks

- in s189-teacher-services-cloud-production subscription
- in s189p01-tsc-pd-rg resource group
- contains tra-production namespace
- will hold production envs
- PIM approval required

## Authentication

### Raising a PIM request

You need to activate the role in the desired cluster below:
<https://portal.azure.com/?Microsoft_Azure_PIMCommon=true#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/azurerbac>

Example: Activate `s189-teacher-services-cloud-test`. It will be approved automatically after a few seconds

### Azure setup

```shell
az login
```

Get access credentials for a managed Kubernetes cluster (passing the environment name):

```shell
make review get-cluster-credentials
```

## Show namespaces

```shell
kubectl get namespaces
```

## Show deployments

```shell
kubectl -n tra-development get deployments
```

## Show pods

```shell
kubectl -n tra-development get pods
```

## Get logs from a pod

Without tail:

```shell
kubectl -n tra-development logs check-childrens-barred-list-qa-some-number
```

Tail:

```shell
kubectl -n tra-development logs check-childrens-barred-list-qa-some-number -f
```

Logs from the ingress:

```shell
kubectl logs deployment/ingress-nginx-controller -f
```

Alternatively you can install kubetail and run:

```shell
kubetail -n tra-development check-childrens-barred-list-qa-*
```

You can also get logs from a deployed app using make with logs:

```shell
make review logs APP_NAME=pr-1234
make qa logs
```

## Open a shell

```shell
kubectl -n tra-development get deployments
kubectl -n tra-development exec -ti deployment/check-childrens-barred-list-pr-1234 -- sh
```

Alternatively you can enter directly on a pod:

```shell
kubectl -n tra-development exec -ti check-childrens-barred-list-qa-some-number -- sh
```

You can run a rails console on a deployed app using make with console:

```shell
make review console APP_NAME=pr-1234
make qa console
```

You can connect using ssh on a deployed app using make with ssh

```shell
make review ssh APP_NAME=pr-1234
make qa ssh
```

## Show CPU / Memory Usage

All pods in a namespace:

```shell
kubectl -n tra-development top pod
```

All pods:

```shell
kubectl top pod -A
```

## More info on a pod

```shell
kubectl -n tra-development describe pods check-childrens-barred-list-somenumber-of-the-pod
```

## Scaling

The app:

```shell
kubectl -n tra-development scale deployment/check-childrens-barred-list-loadtest --replicas 2
```

### Enter on console

```shell
kubectl -n tra-development exec -ti check-childrens-barred-lists-loadtest-some-pod-number -- bundle exec rails c
```

### Running tasks

```shell
kubectl -n tra-development exec -ti check-childrens-barred-list-loadtest-some-pod-number -- bundle exec rake -T
```

### Access the DB

```shell
make install-konduit
bin/konduit.sh app-name -- psql
```

Example of loading test:

```shell
bin/konduit.sh check-childrens-barred-list-loadtest -- psql
```

## More info

For more info see
[Kubernetes cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
