# 3. Use Sidekiq

Date: 2023-07-27

## Status

Accepted

## Context

We need a background job system to allow us to send events to BigQuery.

## Decision

Use the Sidekiq + Rails combination which is in wide use in Teacher Services.

## Consequences

We introduce a new service for developing locally
Our deployment environments need to manage deploying a Redis instance as well
