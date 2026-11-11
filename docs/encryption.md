# Encryption

The application uses [ActiveRecord Encryption](https://guides.rubyonrails.org/active_record_encryption.html) to encrypt sensitive data.

Application-level encryption ensures that we reduce the risk of leaking PII information should
the database ever be compromised.

## Rails DB encryption keys configuration

**Note:** We do not store db encryption keys in Rails credentials, as these cannot be easily set per hosting environment.

For database encryption to work, Rails needs three configuration values:

```
config.active_record.encryption.primary_key
config.active_record.encryption.deterministic_key
config.active_record.encryption.key_derivation_salt
```

The application reads these from environment variables populated either locally from dotenv files, or from the appropriate keyvault secrets.

## Generate ActiveRecord database encryption secrets

To generate or regenerate these configuration values run:

`bin/setup_db_encryption`

It offers to generate a new `RAILS_MASTER_KEY`, then prints the three encryption values as ready-to-paste environment variables.

Paste the resulting output to either your `.env.local` _and_ `.env.test.local` files.

If you are generating application secrets in Azure, amend this output to a valid YAML format and save in the appropriate keyvault.

## Key derivation digest

Keys are derived with SHA-256, the Rails default since `load_defaults 7.1`.

Every encrypted column in this database was originally written under SHA-1, which was the default when they were first encrypted. They were rewritten under SHA-256 by a one-off `pii:re_encrypt` task, run with the service behind the [maintenance page](maintenance-page.md), and the SHA-1 overrides in `config/application.rb` were removed once a companion `pii:verify` task confirmed no row depended on them. Both tasks were deleted afterwards. See https://github.com/DFE-Digital/teaching-record-team-project-board/issues/435.

One thing worth knowing before changing a digest or key again: nothing in the ciphertext records which key derived it, because `store_key_references` is off. There is no way to tell a converted row from an unconverted one in SQL, and no way to count what is left. Any future change needs the same shape of migration, and the only completion check available is reading every row through a type with no previous schemes.

The deterministic columns are the ones that hurt when this goes wrong. A row still under the old key doesn't match a lookup, so a search reports no record for that person rather than failing. The `encrypts` lines in `app/models/` say which columns are deterministic.

Note this is specific to Active Record encryption. `active_support.key_generator_hash_digest_class`, which signs session cookies, moved to SHA-256 back in Rails 7.0 and is not pinned.
