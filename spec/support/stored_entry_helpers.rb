# Helpers for planting barred list entries in the forms older code left behind.
#
# Entries uploaded before ChildrensBarredListEntry gained `encrypts` in January
# 2024 still hold plaintext, and nothing written through the model today can
# produce that. Specs plant it underneath the model instead.
module StoredEntryHelpers
  # Creates an entry stored as plaintext, as one uploaded before encryption
  # would be. It starts under a placeholder name, because the model's uniqueness
  # validation and the unique index would both refuse a second entry for
  # someone already in the table as ciphertext, then has each value replaced.
  #
  # searchable_last_name is left nil unless given: it arrived with encryption
  # and is only filled on save, so entries uploaded before then have none.
  def create_plaintext_entry(searchable_last_name: nil, **attributes)
    intended = build(:childrens_barred_list_entry, **attributes, searchable_last_name:)
    entry = create(:childrens_barred_list_entry,
                   **attributes.merge(first_names: "Placeholder #{SecureRandom.hex(4)}"))

    ChildrensBarredListEntry.encrypted_attributes.each do |attribute|
      store_raw(entry, attribute, intended.public_send(attribute))
    end
    entry
  end

  # Writes well-formed ciphertext that no configured key can read, which is what
  # a value from another environment or a lost key would look like.
  def store_under_unknown_key(record, attribute, value)
    type = ActiveRecord::Encryption::EncryptedAttributeType.new(
      scheme: ActiveRecord::Encryption::Scheme.new(
        deterministic: record.class.type_for_attribute(attribute).deterministic?,
        key_provider: ActiveRecord::Encryption::DerivedSecretKeyProvider.new(SecureRandom.hex(16))
      )
    )

    store_raw(record, attribute, type.serialize(value))
  end

  # Puts bytes in the column untouched.
  #
  # update_columns and update_all both serialize through the attribute's own type,
  # which would encrypt whatever it was given, so neither can plant a value that is
  # deliberately not ciphertext.
  def store_raw(record, attribute, value)
    model = record.class
    column = model.connection.quote_column_name(attribute)

    model.connection.execute(
      model.sanitize_sql_array(
        ["UPDATE #{model.quoted_table_name} SET #{column} = ? WHERE id = ?", value, record.id]
      )
    )
    record.reload
  end

  # The SQL text of every query the block runs, without its bind values.
  def queries_during(&)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)
    queries
  end
end

RSpec.configure { |config| config.include StoredEntryHelpers }
