module BarredListEntries
  # Finds the barred list entries holding plaintext that search can't find:
  # people on the list whom a user searching by their last name and date of
  # birth would be told aren't on it.
  #
  # Search matches searchable_last_name and date_of_birth as ciphertext, on
  # confirmed entries only. An entry whose own searchable_last_name or date of
  # birth isn't ciphertext can only be found through another entry, so those
  # are the ones searched for here.
  #
  # It only reads. It reads ciphertext through the model, under the digest the
  # application is configured with, so it answers for the data as it stands
  # before the SHA-256 conversion.
  class UnfindableEntries
    include Enumerable

    # last_name and date_of_birth are the plaintext search used, kept so the
    # failed searches for the person can be counted. inspect leaves them out,
    # so an error that prints one of these never prints a value.
    Unfindable = Data.define(:id, :confirmed, :uploaded_before_confirmation, :last_name, :date_of_birth) do
      def inspect
        "#<Unfindable id=#{id}>"
      end
      alias_method :to_s, :inspect
    end

    # An entry search couldn't be run for, because its last name or date of
    # birth is ciphertext this environment's keys can't decrypt.
    Unreadable = Data.define(:id)

    # Every Active Record encrypted message starts with "{", and no plaintext
    # name, date, TRN or NI number does. The SQL built from it holds no value.
    CIPHERTEXT_PATTERN = "{%".freeze

    # Yields an Unfindable or an Unreadable for each entry search can't find.
    def each
      candidates.each do |entry|
        found = judge(entry)
        yield found if found
      rescue ActiveRecord::Encryption::Errors::Decryption
        yield Unreadable.new(id: entry.id)
      end
    end

    private

    # Entries search can't match through their own row. A null value is
    # neither plaintext nor ciphertext, but a null searchable_last_name means
    # search can't match the row.
    def candidates
      own_row_unsearchable = [
        "#{quoted(:searchable_last_name)} IS NULL",
        "#{quoted(:searchable_last_name)} NOT LIKE '#{CIPHERTEXT_PATTERN}'",
        "#{quoted(:date_of_birth)} NOT LIKE '#{CIPHERTEXT_PATTERN}'"
      ].join(" OR ")

      ChildrensBarredListEntry.select(:id, :confirmed, :upload_file_hash, :last_name, :date_of_birth)
                              .where(own_row_unsearchable)
                              .find_each
    end

    def judge(entry)
      last_name = readable(entry, :last_name)
      date_of_birth = readable(entry, :date_of_birth)
      return if ChildrensBarredListEntry.search(last_name:, date_of_birth:) # found through another entry

      # upload_file_hash arrived with confirmed, with no backfill, so an
      # unconfirmed entry without one was uploaded before confirmation existed.
      Unfindable.new(id: entry.id, confirmed: entry.confirmed,
                     uploaded_before_confirmation: !entry.confirmed && entry.upload_file_hash.nil?,
                     last_name:, date_of_birth:)
    end

    # Plaintext as it is, and ciphertext through the model's own type.
    def readable(entry, attribute)
      raw = entry.read_attribute_before_type_cast(attribute)
      return raw unless ActiveRecord::Encryption.encryptor.encrypted?(raw)

      ChildrensBarredListEntry.type_for_attribute(attribute).deserialize(raw)
    end

    def quoted(attribute)
      ChildrensBarredListEntry.connection.quote_column_name(attribute)
    end
  end
end
