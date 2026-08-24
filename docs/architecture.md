# Architecture

Check the Children's Barred List (CBL) is a single Rails monolith that lets employers, agencies and local authorities check whether someone appears on the Children's Barred List. This document is the high-level design: what the service is made of, what it talks to, and where to look next.

## Overview

Users sign in with DfE Sign-in and search by last name and date of birth. TRA support staff load the list itself by uploading a CSV through the support interface, so **the data is a point-in-time snapshot, not a live feed**.

CBL has no upstream API. It doesn't call the TRS (formerly DQT) API or read any teaching record, and its outbound integrations are DfE Sign-in, BigQuery, Sentry and Logit.

The stack is Ruby 3.4, Rails 8.1 and Puma, using the GOV.UK Design System through `govuk-components` and `govuk_design_system_formbuilder`, with Propshaft, `jsbundling-rails` and `cssbundling-rails` for assets. It runs in the Teacher Services Cloud AKS clusters — review, test and preproduction in the test cluster, production in its own — as [hosting and observability](hosting.md) sets out.

## Container diagram

This is a [C4](https://c4model.com/) container view: the runnable things CBL is made of, the people who use them, and the systems they depend on. It leaves out uptime monitoring — see [hosting and observability](hosting.md) for that.

![C4 container diagram: employers, agencies and LA users search the barred list through the CBL web app, TRA support users upload it, and the web app shares Azure Postgres and Redis with the Sidekiq worker while talking to DfE Sign-in, BigQuery, Sentry and Logit. The sections below describe each container.](images/container-view.svg)

The source is [`images/container-view.mmd`](images/container-view.mmd); [`images/README.md`](images/README.md) has the steps for regenerating the SVG.

## The containers

### Web app

The Rails application, running under Puma. It serves the search journey (the form at `/` and `/search`, the result at `/result`), the DfE Sign-in flow (`/sign-in` and `/auth/dfe/*`), the support interface at `/support`, which covers CSV uploads, role management and feature flags, and the feedback, terms and conditions, accessibility and cookies pages. okcomputer serves the health check at `/healthcheck`. See [authentication](authentication.md) for the sign-in and authorisation layers.

### Worker

The same Docker image, started with `bundle exec sidekiq -C ./config/sidekiq.yml` — see the `worker_application` module in [`terraform/aks/application.tf`](../terraform/aks/application.tf). It serves four queues, `critical`, `default`, `low` and `analytics`, and retries a failed job once (`config/sidekiq.yml`).

sidekiq-cron runs the scheduled jobs, loading `config/schedule.yml` when the worker starts:

| Job                                   | Schedule    | Purpose                                       |
| ------------------------------------- | ----------- | --------------------------------------------- |
| `DfE::Analytics::EntityTableCheckJob` | Daily 00:30 | Sends table checksums to BigQuery             |
| `TrimSessionsJob`                     | Daily 04:00 | Prunes expired rows from the `sessions` table |

### Database

An Azure Postgres flexible server, provisioned from the shared teacher-services-cloud module in [`terraform/aks/databases.tf`](../terraform/aks/databases.tf). It holds the barred list entries, DfE Sign-in users and their sessions, role codes, search logs, feedback, feature flags, and the Rails sessions themselves — CBL stores sessions with `activerecord-session_store` (`config/initializers/session_store.rb`), which is why the sessions table needs nightly trimming.

The models encrypt personal data with Active Record encryption, and some columns are deterministic so that they can be searched. See [encryption](encryption.md) for the constraints that places on the service.

### Cache and queues

An Azure Redis instance, also from `terraform/aks/databases.tf`. It backs the Sidekiq queues and holds one piece of application state: the rows a CSV upload rejected, cached for an hour under the upload's file hash so that the preview page can show them (`app/services/failed_childrens_barred_list_entries.rb`).

## Where to go next

- [Data flows](data-flows.md) — how the barred list gets in, and what happens during a search
- [Authentication](authentication.md) — the basic auth gate, DfE Sign-in, and support access
- [Hosting and observability](hosting.md) — environments, deployment, monitoring
- [Encryption](encryption.md) — how PII is protected and what that constrains
- [Disaster recovery](disaster-recovery.md) — what to do when the database is lost or corrupted
- [AKS cheatsheet](aks-cheatsheet.md) — day-to-day cluster commands

## Architecture Decision Records (ADRs)

We keep track of architecture decisions in [Architecture Decision Records (ADRs)](/adr/).

Use `rladr` to generate the boilerplate for a new record:

```bash
bin/bundle exec rladr new title
```
