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

Keys are derived with PBKDF2-HMAC-**SHA-1**, not the SHA-256 that Rails has defaulted to since `load_defaults 7.1`. `config/application.rb` pins the digest back to SHA-1, and that pin is load-bearing: production ciphertext was written under it, and the digest feeds every derived key.

Changing the digest breaks reads in two different ways, depending on how a column is declared. The `encrypts` lines in `app/models/` are the authoritative list of which is which.

- **Deterministic columns** (`deterministic: true`) are queried by encrypting the search term and matching the stored ciphertext. Under a new digest the ciphertext no longer matches, so lookups return nothing — no exception, no log entry, searches quietly go empty. Two indexes depend on this working.
- **Non-deterministic columns** fail to decrypt outright, which at least surfaces loudly.

`config.active_record.encryption.support_sha1_for_non_deterministic_encryption` sits next to the pin and does nothing while the digest is SHA-1 — it registers a previous scheme whose derived key is byte-identical to the current one. It starts doing work only when the digest moves to SHA-256, and even then it covers the non-deterministic columns alone.

To be clear about the risk being carried: PBKDF2-HMAC-SHA-1 is not broken, and the collision attacks that retired SHA-1 for signatures do not apply to key derivation. SHA-256 is the modern default and where we should end up, but this is a modernisation task rather than a live vulnerability.

### Moving to SHA-256

Set `support_sha1_for_non_deterministic_encryption` before moving `hash_digest_class`, so non-deterministic values written under SHA-1 stay readable through the previous scheme.

That fallback does not extend to the deterministic columns. Those have to be read and rewritten under the new digest, and lookups against them will miss for any row not yet rewritten — so the migration needs to account for the service being live, or run behind a maintenance window.
