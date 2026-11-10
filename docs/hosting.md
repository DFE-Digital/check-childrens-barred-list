# Hosting and observability

CBL runs in the Teacher Services Cloud AKS clusters, deployed from GitHub Actions and configured with Terraform. This document covers the environments, how a change reaches them, and how you find out when something is wrong. For what runs in each environment, see [architecture](architecture.md).

## Environments

| Environment   | Cluster    | Namespace         | Web replicas | Notes                                                      |
| ------------- | ---------- | ----------------- | ------------ | ---------------------------------------------------------- |
| Review        | test       | `tra-development` | 1            | One per pull request, in-cluster Postgres and Redis        |
| Test          | test       | `tra-development` | 1            |                                                            |
| Preproduction | test       | `tra-test`        | 1            |                                                            |
| Production    | production | `tra-production`  | 2            | Postgres HA, uptime monitoring, `.education.gov.uk` domain |

Per-environment configuration lives in `terraform/aks/config/*.tfvars.json`, environment variables in `terraform/aks/config/app_config.yml`, and secrets in the environment's Azure key vault. `terraform/custom_domains/` handles the custom domains separately.

Review apps differ from the rest: `deploy_azure_backing_services` is false, so Postgres and Redis run inside the cluster rather than as Azure services, and DfE Sign-in is always bypassed (see [authentication](authentication.md)).

## Deploying

[`build-and-deploy.yml`](../.github/workflows/build-and-deploy.yml) builds one Docker image, pushes it to `ghcr.io/dfe-digital/check-childrens-barred-list`, and deploys it:

- **On a pull request** labelled `deploy`, to a review app. Without the label it deploys nothing.
- **On merge to `main`**, to test and preproduction, then to production.
- **On demand**, to a single environment chosen from the workflow dispatch input.

Both the web and worker deployments run from that same image, and the web container's startup command runs `db:migrate` before booting the server, so migrations run on deploy.

The workflow posts build and deploy failures to a Teams channel through `TEAMS_WEBHOOK_URL`. Separately, `validate-infrastructure.yml` runs a Terraform plan against production every day at 07:00 UTC and reports drift and failures to the SD Infra alerts channel (`TEAMS_WEBHOOK_URL_INFRA`).

To take an environment offline for planned maintenance, or to deploy while it is offline, see [maintenance page](maintenance-page.md).

## Warning users about downtime

Before planned downtime, turn on the `downtime_banner` feature flag at `/support/features` in the environment going down. While it's on, every page shows a notification banner saying when the service will be unavailable. The wording, with the date and the start and end times, is in `app/views/layouts/base.html.erb`, so update it and deploy before turning the flag on.

Signed-out users go straight from `/sign-in` to DfE Sign-in without seeing a page of the service, so the banner only reaches people once they've signed in. Turn it on far enough ahead for regular users to see it, tell users through other channels as well, and turn it off once the downtime has passed.

## Observability

| Concern   | Where it goes                                                                       |
| --------- | ----------------------------------------------------------------------------------- |
| Errors    | Sentry, with PII filtered out (`config/initializers/sentry.rb`)                     |
| Logs      | Logit, in every environment (`enable_logit`); structured by `rails_semantic_logger` |
| Uptime    | StatusCake, probing `/healthcheck` and the SSL certificate in production only       |
| Analytics | BigQuery, via `dfe-analytics`                                                       |
| Health    | `/healthcheck`, served by okcomputer                                                |

As well as the usual parameter filtering, Sentry strips the `DETAIL:` line from `RecordNotUnique` exceptions, because Postgres puts the conflicting values — names and dates of birth — into that message.

The health check reports three things (`config/initializers/okcomputer.rb`): a Postgres connection, a `database_integrity` check, and the deployed commit SHA, which is optional so that a missing `COMMIT_SHA` doesn't fail the probe. Production also sets `probe_path` to `/healthcheck`, so the same endpoint serves as the Kubernetes container probe and as what StatusCake watches.

Analytics events go out on the worker's dedicated `analytics` queue, to the `teaching-qualifications` GCP project, into a per-environment dataset (`terraform/aks/dfe_analytics.tf`). The dataset is `ccbl_events_<environment>` unless the environment's tfvars set `gcp_dataset_name`, which preproduction does — its dataset is `ccbl_events_preprod`, not `ccbl_events_preproduction`. They authenticate with Azure workload identity federation rather than a service account key, which is why the worker deployment is the one carrying `enable_gcp_wif`. `config/analytics.yml` and its siblings `analytics_pii.yml`, `analytics_hidden_pii.yml` and `analytics_blocklist.yml` control which fields go out and which count as PII.

## Running things in the cluster

See the [AKS cheatsheet](aks-cheatsheet.md) for connecting to an environment, opening a console, or reading logs, and [disaster recovery](disaster-recovery.md) for restoring a lost or corrupted database.
