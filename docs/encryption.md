# Encryption

The application uses [ActiveRecord Encryption](https://guides.rubyonrails.org/active_record_encryption.html) to encrypt sensitive data.

Application-level encryption ensures that we reduce the risk of leaking PII information should
the database ever be compromised.

## Rails DB encryption keys configuration

**Note:** We do not store db encryption keys in Rails credentials, as these cannot be easily set per hosting environment.

For database encryption to work, Rails needs three configuration values:

```
config.active_record_encryption.primary_key
config.active_record_encryption.deterministic_key
config.active_record_encryption.key_derivation_salt
```

The application reads these from environment variables populated either locally from dotenv files, or from the appropriate keyvault secrets.

## Generate ActiveRecord database encryption secrets

To generate or regenerate these configuration values run:

`bin/rails setup_db_encryption`

Paste the resulting output to either your `.env.local` _and_ `.env.test.local` files.

If you are generating application secrets in Azure, amend this output to a valid YAML format and save in the appropriate keyvault.
