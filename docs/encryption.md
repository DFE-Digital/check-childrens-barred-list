# Encryption

The application uses [ActiveRecord Encryption](https://guides.rubyonrails.org/active_record_encryption.html) to encrypt sensitive data.

Application-level encryption ensures that we reduce the risk of leaking PII information should
the database ever be compromised.

## Encryption keys

Rails encrypts data using a key that is stored outside of version control. In deployed environments
we use the `RAILS_MASTER_KEY` environment variable to pass the key to the application.

For local development, the key is stored in `config/master.key`. This file is not encrypted, so it
should be kept secret.

## Rails DB encryption configuration

**Note:** We do not store db encryption keys in Rails credentials, as these cannot be easily set per hosting environment.

For database encryption to work, Rails needs three configuration values:

```
config.active_record_encryption.primary_key
config.active_record_encryption.deterministic_key
config.active_record_encryption.key_derivation_salt
```

The application reads these from environment variables populated either locally from `.env.local` or from the appropriate keyvault secret.

To generate or regenerate these configuration values run:

`bin/rails setup_db_encryption`

Paste the resulting output to either your `.env.local` _and_ `.env.test.local` files.

If you are generating application secrets in Azure, amend this output to a valid YAML format for the appropriate keyvault.
