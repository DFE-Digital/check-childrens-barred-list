# Data flows

CBL has two data flows: loading the barred list into the database, and searching it. This document covers both. For the containers they run in, see [architecture](architecture.md).

## Loading the barred list

The list arrives as a CSV that a support user uploads at `/support/uploads/new`. Upload, preview and confirm are three separate requests, so the support user sees the parsed rows before they become searchable.

1. **Upload.** `SupportInterface::UploadForm` hands the file's contents to `CreateChildrensBarredListEntries`, which parses it as ISO-8859-1 and creates one `ChildrensBarredListEntry` per row, with `confirmed: false`. It tags every row from that file with `upload_file_hash`, the SHA-256 of the file's contents, and the rest of the flow keys on that hash. The form catches `CSV::MalformedCSVError` and reports it as a file error, so a malformed file fails the upload rather than loading in part.
2. **Normalisation.** The parser normalises the incoming values: it left-pads TRNs to seven digits, strips titles (`Mr`, `Mrs`, `Miss`, `Ms`, `Dr`, `Prof`) from names and title-cases them, and parses dates of birth into `YYYY-MM-DD`. A date it can't parse becomes `nil`, which then fails the presence validation.
3. **Rejection.** `ChildrensBarredListEntry` rejects a row that fails validation — a missing name or date of birth, a national insurance number in the wrong format, a duplicate of an entry that already exists (last name, first names and date of birth together must be unique), or a row that doesn't have exactly six columns. The six-column check catches a file in a different format, where the columns would shift and the values would load into the wrong fields without raising an error. `FailedChildrensBarredListEntries` then writes the rejected rows to Redis under the file hash, with a one-hour expiry.
4. **Preview.** The preview page reads the rejected rows back out of Redis and the unconfirmed rows out of Postgres, both keyed by the file hash, and shows them side by side. **The rejected rows expire after an hour**, so a preview left open longer than that shows only the rows that parsed; the unconfirmed entries in Postgres are unaffected.
5. **Confirm or cancel.** Confirming sets `confirmed: true` and `confirmed_at` on every unconfirmed row with that file hash (`ConfirmChildrensBarredListEntries`), and cancelling deletes them (`DeleteUnconfirmedChildrensBarredListEntries`). Either way, the controller clears the cached rejected rows from Redis first.

**An upload adds to the list rather than replacing it**, and there's no journey for removing an entry. Re-uploading a corrected file has its unchanged rows rejected as duplicates.

## Searching

The search journey is two pages: the form, served at both `/` and `/search`, and the result at `/result`. There's no results list — a search either matches exactly one entry or it matches nothing.

1. `SearchForm` validates the last name and the three date-of-birth fields. `DayMonthYearValidator` handles the partial and impossible dates a three-field date input allows, and rejects a date of birth in the future, more than 100 years ago, or less than 16 years ago. The month field accepts a name as well as a number, so "Jan" and "1" both work.
2. `ChildrensBarredListEntry.search` looks for a confirmed entry whose `date_of_birth` matches and whose `searchable_last_name` matches the search term transliterated to ASCII, downcased and stripped. The model populates that normalised column on save, so accents and casing in either the source file or the search box don't affect the match. Searches ignore unconfirmed entries, so an upload becomes visible to users only once someone confirms it.
3. Every valid search writes a `SearchLog` row recording the DfE Sign-in user, the search terms and whether a record was returned. This is the service's audit trail of which checks were made, and by whom.
4. The user sees either the matching record or the "no record found" page.

The lookup works only because those columns use Active Record's deterministic encryption: Rails encrypts the search term and compares it against the stored ciphertext, so identical values produce identical ciphertext. `SearchLog` encrypts the same fields the same way, so you can query the audit trail by name or date of birth — from a console, or in BigQuery, where `config/analytics.yml` sends the `search_logs` table. No support screen surfaces it.

See [encryption](encryption.md) for what deterministic encryption constrains, in particular the key derivation digest: **changing it makes every search return nothing**, with no exception and no log entry to say why.
