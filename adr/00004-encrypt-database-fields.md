# 8. Encrypt database fields

Date: 2023-08-17

## Status

Accepted

## Context

Currently the database is encrypted at rest but unauthorised access to a running database instance could still result in exposure of PII.

We want to encrypt the PII fields to lessen the impact of any breach of the database.

Rails 7 introduced [encryption](https://edgeguides.rubyonrails.org/active_record_encryption.html) as a feature. It seamlessly encrypts the data
on write and decrypts it on read provided you have the encryption keys.

This means that we can encrypt the PII fields in the database without any change to the
way we use and display the data.

## Decision

We will use ActiveRecord Encryption to encrypt the PII fields on a per-model basis.

## Consequences

All environments will require the Active Record encryption keys to be able to decrypt the PII fields. They are supplied as environment variables rather than through Rails credentials, so each hosting environment can hold its own.

See the `docs/encryption.md` for details on managing the keys.
