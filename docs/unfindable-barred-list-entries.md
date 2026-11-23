# Unfindable barred list entries

Some entries in `childrens_barred_list_entries` still hold plaintext, and search can't find a person through a plaintext entry. This document explains why, and how two read-only rake tasks list the barred people search misses and count the searches that already missed them.

## Why search misses plaintext entries

PR #213 added `encrypts` to `ChildrensBarredListEntry` in January 2024 without rewriting existing rows, so entries uploaded before then still hold plaintext. Some of those people were uploaded again later, which added a ciphertext entry beside the plaintext one, because the unique index on `(first_names, last_name, date_of_birth)` compares stored bytes.

`ChildrensBarredListEntry.search` matches `searchable_last_name` and `date_of_birth` as deterministic ciphertext, and only entries with `confirmed` set. It never looks at first names. So search finds a person through any confirmed ciphertext entry with their last name and date of birth, and never through a plaintext one:

- `searchable_last_name` arrived with `encrypts` and is only filled on save, so plaintext entries have none.
- `confirmed` arrived on 17 August 2023 with a default of false and no backfill. Entries uploaded before then were real list uploads, unconfirmed only because confirmation didn't exist yet, and search has required it since.
- The model can't read plaintext either, because `support_unencrypted_data` is off.

A plaintext entry with a confirmed ciphertext entry for the same last name and date of birth is still found, through that entry. Any other is a barred person a user searching for them has been told isn't on the list, since January 2024 at the latest, or since August 2023 for entries uploaded before confirmation existed. Converting the entry to ciphertext won't change that, because it still has no `searchable_last_name`.

**Treat any unfindable entry as a safeguarding finding, and raise it with the service owner before deciding anything else.** The one exception is an entry that's unconfirmed but has an upload hash: that's an upload nobody confirmed or cancelled, and search was never meant to find it.

## Running the reports

| Task                                  | Does                                                                                            | Speed                                     |
| ------------------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `barred_list_entries:unfindable`      | Lists each entry search can't find, and counts them                                             | Quick. Run it first                       |
| `barred_list_entries:failed_searches` | Finds the same entries, then counts the logged searches for each person that returned no record | Reads all of `search_logs` once per entry |

Both only read. They take no locks, write nothing, and print counts and row ids only, never a name, date of birth, TRN, NI number or ciphertext. Record their output on the board ticket, never in a pull request, since the app repository is public.

`search_logs` has no index on the name or date, so `failed_searches` reads that whole table for every unfindable entry. Run it after `unfindable`, and outside working hours on production if `unfindable` listed many entries. It's safe to stop partway, since it only reads, and each line is printed as it goes.

On a deployed environment, run them in the worker pod. These examples are for production, which needs PIM:

```bash
make production get-cluster-credentials
kubectl -n tra-production exec deployment/check-childrens-barred-list-production-worker -- \
  sh -c 'cd /app && bundle exec rails barred_list_entries:unfindable'
kubectl -n tra-production exec deployment/check-childrens-barred-list-production-worker -- \
  sh -c 'cd /app && bundle exec rails barred_list_entries:failed_searches'
```

| Environment   | Make target     | Namespace         | Worker deployment                                  |
| ------------- | --------------- | ----------------- | -------------------------------------------------- |
| Test          | `test`          | `tra-development` | `check-childrens-barred-list-test-worker`          |
| Preproduction | `preproduction` | `tra-test`        | `check-childrens-barred-list-preproduction-worker` |
| Production    | `production`    | `tra-production`  | `check-childrens-barred-list-production-worker`    |

## How they find unfindable entries

Both read only the entries search can't match through their own row: those whose `searchable_last_name` is empty or not ciphertext, or whose `date_of_birth` isn't ciphertext. They pick them in SQL by whether the stored value starts with `{`, as every Active Record encrypted message does.

For each, they take the last name and date of birth as stored if they're plaintext, or decrypt them through the model if not, then run the service's own search. If it returns nothing, the entry is unfindable. That includes a ciphertext entry with no `searchable_last_name`, which is what encrypting a plaintext row without saving it through the model leaves.

They answer for the data as it stands before the SHA-256 conversion (board #435), since they decrypt under the digest the application is configured with.

## Reading `barred_list_entries:unfindable`

| Line                                                                      | Means                                                                                                                                                |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `unfindable entry: A (confirmed: ..., uploaded before confirmation: ...)` | searching for A's last name and date of birth returns no record. `uploaded before confirmation` is true when A is unconfirmed and has no upload hash |
| `unreadable entry: A`                                                     | A's last name or date of birth is an encrypted message this environment's keys can't decrypt, so the report couldn't search for A                    |

| Count                                             | Counts                                                                                                                                                                                              |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `entries`                                         | every entry in `childrens_barred_list_entries`                                                                                                                                                      |
| `entries_holding_plaintext`                       | entries with a value in any encrypted attribute that doesn't start with `{`, so isn't ciphertext. A ciphertext entry with no `searchable_last_name` isn't counted here, though it can be unfindable |
| `unreadable_entries`                              | entries the report had to read but couldn't, so couldn't search for                                                                                                                                 |
| `unfindable_entries`                              | entries search can't find, through their own row or any other                                                                                                                                       |
| `confirmed_unfindable_entries`                    | the confirmed ones among `unfindable_entries`                                                                                                                                                       |
| `unfindable_entries_uploaded_before_confirmation` | the unfindable entries that are unconfirmed and have no upload hash. `upload_file_hash` arrived with `confirmed` and wasn't backfilled, so these were uploaded before confirmation existed          |

An unfindable entry that is neither confirmed nor uploaded before confirmation is an upload nobody confirmed or cancelled.

## Reading `barred_list_entries:failed_searches`

| Line                                     | Means                                                                         |
| ---------------------------------------- | ----------------------------------------------------------------------------- |
| `failed searches for entry A: N`         | N logged searches for A's last name and date of birth returned no record      |
| `failed_searches_for_unfindable_entries` | those added up, across every unfindable entry. Unreadable entries are skipped |

The count is a floor. Searches were first logged on 3 January 2024, but only those that found a record until 18 March 2024, so no failed search before then is in the log. The log also holds the last name as typed, so only the stored spelling and its lowercase, uppercase and capitalised forms are tried. Two unfindable entries with the same last name and date of birth each count the same searches.
