# Plants ciphertext written under the key derivation this application used before
# it moved to SHA-256, so specs can prove such rows are no longer readable.
# Nothing in the ciphertext records which digest derived its key, so the only way
# to test the boundary is to write a known-SHA-1 value deliberately.
module EncryptionDigestHelpers
  def write_under_sha1(record, attribute, value)
    write_raw(record, attribute, sha1_type_for(record.class, attribute).serialize(value))
  end

  # Puts bytes in the column untouched.
  #
  # update_columns and update_all both serialize through the attribute's own type,
  # which would encrypt whatever it was given, so neither can plant a value that is
  # already ciphertext.
  def write_raw(record, attribute, value)
    model = record.class
    column = model.connection.quote_column_name(attribute)

    model.connection.execute(
      model.sanitize_sql_array(
        ["UPDATE #{model.quoted_table_name} SET #{column} = ? WHERE id = ?", value, record.id]
      )
    )
    record.reload
  end

  private

  def sha1_type_for(model, attribute)
    deterministic = model.type_for_attribute(attribute).deterministic?

    ActiveRecord::Encryption::EncryptedAttributeType.new(
      scheme: ActiveRecord::Encryption::Scheme.new(
        deterministic:,
        key_provider: sha1_key_provider(deterministic:)
      ),
      default: model.columns_hash[attribute.to_s].default
    )
  end

  def sha1_key_provider(deterministic:)
    config = ActiveRecord::Encryption.config
    password = deterministic ? config.deterministic_key : config.primary_key

    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      password,
      key_generator: ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
    )
  end
end

RSpec.configure { |config| config.include EncryptionDigestHelpers }
