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

Rails 7.1 changed the digest used to derive encryption keys from SHA-1 to SHA-256. Every encrypted column in this database was written under SHA-1, so the change cannot be taken until the existing ciphertext has been rewritten. The move is tracked at https://github.com/DFE-Digital/teaching-record-team-project-board/issues/435.

Keys are now derived with SHA-256. `config/application.rb` keeps one override:

```ruby
config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true
```

That registers a SHA-1 previous scheme, which carries the four non-deterministic columns: `ChildrensBarredListEntry#trn` and `#national_insurance_number`, and `DsiUser#first_name` and `#last_name`. They decrypt under either digest while it is set.

It does nothing for the seven deterministic columns: `ChildrensBarredListEntry#date_of_birth`, `#first_names`, `#last_name` and `#searchable_last_name`, `SearchLog#date_of_birth` and `#last_name`, and `DsiUser#email`. The scheme it adds is non-deterministic, and Rails only attaches a previous scheme to an attribute whose determinism matches, so those seven have no fallback and must be rewritten. Until they are, a lookup against a row still holding SHA-1 ciphertext returns nothing, with no exception and no log entry, so a search for a barred person reports no record. Reading one raises.

PBKDF2-HMAC-SHA-1 is not broken, and the collision attacks that retired SHA-1 for signatures do not apply to key derivation. This is a modernisation task rather than a live vulnerability.

### Converting the data

```bash
make test railstask TASK=pii:re_encrypt
make test railstask TASK=pii:verify
```

`railstask` ties the task to your terminal session, which is fine for verify and for small environments. In production, run the conversion detached in the worker pod, as the runbook on the ticket above describes, so a dropped connection cannot stop it mid-batch.

`pii:re_encrypt` rewrites every encrypted column under the current digest, in batches, one transaction per batch. Each batch logs the arguments to resume with, so an interruption is recovered by copying `pii:re_encrypt[DsiUser,12345]` from the log. Rerunning it is safe: it writes the same plaintext back, though the non-deterministic columns get fresh ciphertext each pass. It writes with `update_columns`, so it runs no callbacks, sends no analytics events, and leaves `updated_at` alone.

`pii:verify` reads every encrypted column through a type with no previous schemes and exits non-zero if anything fails, so it answers the only question that matters: would these rows survive the override being removed. It has to build that type itself, because the models' own types have the SHA-1 fallback and would report success right up until the override goes. It also fails a value that decrypts to more ciphertext, because a value encrypted twice reads cleanly.

Nothing in the ciphertext records which digest derived its key (`store_key_references` is off), so there is no way to count remaining rows in SQL. Reading them is the only check.

Both tasks must be run with the service behind the [maintenance page](maintenance-page.md). Once the digest change is deployed, a search misses any entry not yet converted, and any write to a `DsiUser`, such as signing in, raises on a row not yet converted, because dfe-analytics reads each attribute's old value to track the change.

The unique index on `childrens_barred_list_entries` covers names and date of birth as deterministic ciphertext, so it cannot see that a SHA-1 row and a SHA-256 row hold the same person. If both exist, converting the SHA-1 one fails with `ActiveRecord::RecordNotUnique` naming that row.

The override comes out once `pii:verify` reports nothing in production.

Note this is all specific to Active Record encryption. `active_support.key_generator_hash_digest_class`, which signs session cookies, moved to SHA-256 back in Rails 7.0 and is not pinned.
