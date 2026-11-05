# Maintenance page

The maintenance page is a static page that stands in for the service while it is offline for planned maintenance or an incident. Users keep the URL they asked for, so refreshing after the maintenance ends takes them back to the page they wanted. It comes from the Teacher Services Cloud [maintenance page template](https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/maintenance-page.md).

## How it works

`maintenance_page/` holds an nginx image serving `html/index.html`, the Kubernetes manifests for it, and the scripts that switch traffic. Enabling maintenance deploys the image as `check-childrens-barred-list-maintenance` in the environment's namespace, points the environment's internal ingress at it, and adds two ingresses on `teacherservices.cloud`: a temp host that still reaches the app, for checking it before users get it back, and a maintenance host that shows the page directly.

Front Door forwards requests with the origin's own hostname (`null_host_header` in `terraform/custom_domains/environment_domains/main.tf`), so the internal ingress is the only one on a user's path. Terraform also creates an ingress for each `gov_uk_host_names` entry, which the scripts leave alone.

| Environment   | Namespace         | Public host                                                              | Temp host, reaches the app                                                          | Maintenance host                                                                           |
| ------------- | ----------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Test          | `tra-development` | `https://test.check-the-childrens-barred-list.education.gov.uk`          | `https://check-childrens-barred-list-test-temp.test.teacherservices.cloud`          | `https://check-childrens-barred-list-test-maintenance.test.teacherservices.cloud`          |
| Preproduction | `tra-test`        | `https://preproduction.check-the-childrens-barred-list.education.gov.uk` | `https://check-childrens-barred-list-preproduction-temp.test.teacherservices.cloud` | `https://check-childrens-barred-list-preproduction-maintenance.test.teacherservices.cloud` |
| Production    | `tra-production`  | `https://check-the-childrens-barred-list.education.gov.uk`               | `https://check-childrens-barred-list-production-temp.teacherservices.cloud`         | `https://check-childrens-barred-list-production-maintenance.teacherservices.cloud`         |

The page answers `/` with a 200 and every other path with a 500 and the same page. That includes `/healthcheck`, so while the page is up StatusCake alerts in production, and the health check in `build-and-deploy.yml`'s domains jobs fails.

DfE Sign-in returns users to `DFE_SIGN_IN_REDIRECT_URL`, a fixed setting per environment, rather than to the host they started on. Signing in through the temp host therefore ends on the maintenance page unless that setting names the temp host.

## Enabling and disabling

Run the [maintenance workflow](../.github/workflows/maintenance.yml):

```bash
gh workflow run maintenance.yml -f environment=production -f mode=enable
```

It builds the image from `maintenance_page/` on the branch it runs from, deploys it, and lists the temp hosts in the run summary. Check the public host shows the page before carrying on.

To bring the app back:

```bash
gh workflow run maintenance.yml -f environment=production -f mode=disable
```

That resets the internal ingress to the app and deletes the maintenance deployment, its service, and the temp and maintenance ingresses.

## Deploying while the maintenance page is up

Every deploy is a terraform apply, and the apply rewrites the environment's ingresses from its tfvars. By default that points them at the app, which takes the maintenance page down part way through the deploy. Set `send_traffic_to_maintenance_page` to `true` in `terraform/aks/config/<environment>.tfvars.json` on the branch being deployed and the apply points the ingresses at the maintenance service instead.

A merge to `main` deploys `main`'s tfvars to every environment, through to production. Unless the flag is `true` on `main` itself, that merge puts users back on the app. Freeze merges to `main` for as long as an environment has to stay behind the page.

To bring the app back, set it to `false` and deploy: that apply resets the ingresses. Then run the maintenance workflow in `disable` mode to delete the maintenance deployment and the temp ingress. Running `disable` on its own also resets the ingresses, but the next apply undoes that while the flag is still `true`.

With the flag `true` and maintenance not enabled, the ingresses point at a service that doesn't exist and the environment answers 503.

## Changing the message

Edit `maintenance_page/html/index.html` on a branch, push it, and run the workflow from that branch:

```bash
gh workflow run maintenance.yml --ref <branch> -f environment=production -f mode=enable
```

The header and footer are copied from the service's own layout, without the footer links to the service's own pages, which would only show the maintenance page while it's up. The styles and assets are govuk-frontend 6.3.0 from `node_modules`. They don't follow later govuk-frontend upgrades, which only matters if the page starts to look out of place.

## Running it without the workflow

The workflow runs the same make targets you can run from a laptop, signing in to Azure as the repository, so it needs no PIM. From a laptop they need Docker, a GitHub token with `write:packages`, and PIM for the environment's subscription, which for production needs approval:

```bash
make production enable-maintenance GITHUB_TOKEN=<token>
make production disable-maintenance
```

To point an environment at an image that has already been built, pass its tag. A running maintenance deployment names the image, and the tag is the part after the colon:

```bash
kubectl -n tra-production get deployment check-childrens-barred-list-maintenance -o jsonpath='{.spec.template.spec.containers[0].image}'
MAINTENANCE_IMAGE_TAG=<tag> make production maintenance-fail-over
```

`maintenance-fail-over` stops on an unbound variable without `MAINTENANCE_IMAGE_TAG`.

## The first image

The first push creates the `check-childrens-barred-list-maintenance` package in the DFE-Digital organisation, and its settings need setting by hand before the cluster can pull it. In [GitHub packages](https://github.com/orgs/DFE-Digital/packages), open the package, connect it to this repository, give the repository Admin access under "Manage Actions access", and change its visibility to public.

Do the first enable on test. Until the package is public the pods cannot pull the image, so the enable fails at its wait for the maintenance app, before any traffic moves. Set the package up, then run the enable again.
