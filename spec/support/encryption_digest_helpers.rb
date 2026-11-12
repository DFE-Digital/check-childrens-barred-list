# Helpers for exercising the move of Active Record encryption key derivation from
# SHA-1 to SHA-256. Nothing in the ciphertext records which digest derived its
# key, so specs have to plant a known-SHA-1 row and read it back deliberately.
module EncryptionDigestHelpers
  # Writes ciphertext the way this application did before the digest changed.
  def write_under_sha1(record, attribute, value)
    write_raw(record, attribute, sha1_type_for(record.class, attribute).serialize(value))
  end

  # Puts bytes in the column untouched.
  #
  # update_columns and update_all both serialize through the attribute's own type,
  # which would encrypt whatever it was given, so neither can plant a value that is
  # already ciphertext or is deliberately not ciphertext at all.
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

  # Whether the stored value survives without any SHA-1 fallback, which is the
  # question that decides when support_sha1_for_non_deterministic_encryption can go.
  def readable_under_sha256?(record, attribute)
    raw = record.reload.read_attribute_before_type_cast(attribute)
    return true if raw.nil?

    strict_sha256_type_for(record.class, attribute).deserialize(raw)
    true
  rescue ActiveRecord::Encryption::Errors::Base
    false
  end

  def sha1_type_for(model, attribute)
    deterministic = model.type_for_attribute(attribute).deterministic?

    ActiveRecord::Encryption::EncryptedAttributeType.new(
      scheme: ActiveRecord::Encryption::Scheme.new(
        deterministic:,
        key_provider: sha1_key_provider(deterministic:)
      ),
      default: column_default_for(model, attribute)
    )
  end

  def strict_sha256_type_for(model, attribute)
    ActiveRecord::Encryption::EncryptedAttributeType.new(
      scheme: ActiveRecord::Encryption::Scheme.new(
        deterministic: model.type_for_attribute(attribute).deterministic?,
        support_unencrypted_data: false
      ),
      default: column_default_for(model, attribute)
    )
  end

  private

  def sha1_key_provider(deterministic:)
    config = ActiveRecord::Encryption.config
    password = deterministic ? config.deterministic_key : config.primary_key

    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      password,
      key_generator: ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
    )
  end

  def column_default_for(model, attribute)
    model.columns_hash[attribute.to_s].default
  end
end

RSpec.configure { |config| config.include EncryptionDigestHelpers }
