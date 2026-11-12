module Pii
  # Counts encrypted values that cannot be read under the current digest alone,
  # or that decrypt to more ciphertext, and returns that count.
  #
  # It deliberately does not use the models' own attribute types.
  # support_sha1_for_non_deterministic_encryption gives those a SHA-1 fallback, so
  # they read unconverted rows happily and would report success right up until
  # that setting is removed and the rows became unreadable for good. Nothing in
  # the ciphertext records which digest derived its key, so reading every row is
  # the only way to answer the question.
  class Verifier
    # Enough to diagnose a pattern, few enough that a run against an unconverted
    # production table cannot exhaust memory or flood the log pipeline. Applied
    # per model, so a later model's rows are still named when an earlier one
    # fills it.
    SAMPLE_LIMIT = 50

    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def call
      total = MODEL_NAMES.sum { |name| verify(name.constantize) }
      logger.info("pii:verify found #{total.zero? ? "no" : total} unreadable attributes")
      total
    end

    private

    attr_reader :logger

    def verify(model)
      unreadable = 0
      sample = []

      model.find_each do |record|
        unreadable_attributes(record).each do |failure|
          unreadable += 1
          sample << failure if sample.size < SAMPLE_LIMIT
        end
      end

      log_model(model, unreadable, sample)
      unreadable
    end

    def log_model(model, unreadable, sample)
      return logger.info("pii:verify #{model.name}: 0 unreadable") if unreadable.zero?

      sample.each { |failure| logger.error("pii:verify unreadable #{failure}") }
      logger.error("pii:verify #{model.name}: #{unreadable} unreadable, #{sample.size} listed above")
    end

    def unreadable_attributes(record)
      ENCRYPTED_ATTRIBUTES.fetch(record.class.name).filter_map do |attribute|
        next if readable?(record, attribute)

        "#{record.class.name}##{record.id}.#{attribute}"
      end
    end

    def readable?(record, attribute)
      raw = record.read_attribute_before_type_cast(attribute)
      return true if raw.nil?

      value = strict_type_for(record.class, attribute).deserialize(raw)

      # Decrypting proves the key, not the contents. A value encrypted twice
      # decrypts cleanly to ciphertext, and would count as readable here while
      # the application shows that ciphertext as someone's name.
      !ActiveRecord::Encryption.encryptor.encrypted?(value)
    rescue ActiveRecord::Encryption::Errors::Configuration
      # Not a property of the row. Swallowing it would report every row in the
      # database as unreadable and send the reader looking for corrupt data.
      raise
    rescue ActiveRecord::Encryption::Errors::Base
      false
    end

    def strict_type_for(model, attribute)
      @strict_types ||= {}
      @strict_types[[model.name, attribute]] ||= build_strict_type(model, attribute)
    end

    # support_unencrypted_data has to be pinned false rather than left to the
    # global. handle_deserialize_error returns the raw ciphertext instead of
    # raising when it is true, so inheriting a true would make every row look
    # readable and take this check silently green.
    def build_strict_type(model, attribute)
      ActiveRecord::Encryption::EncryptedAttributeType.new(
        scheme: ActiveRecord::Encryption::Scheme.new(
          deterministic: DETERMINISTIC_ATTRIBUTES.fetch(model.name, []).include?(attribute),
          support_unencrypted_data: false
        ),
        default: model.columns_hash[attribute.to_s].default
      )
    end
  end
end
