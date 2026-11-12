module Pii
  # Rewrites every encrypted attribute under the current key-derivation digest.
  class ReEncryptor
    BATCH_SIZE = 1_000

    # Resuming starts at that model and processes every later one in full. Each
    # batch logs the arguments to pass back.
    def initialize(resume_model: nil, resume_id: nil, logger: Rails.logger)
      if resume_model.present? && MODEL_NAMES.exclude?(resume_model)
        raise ArgumentError, "#{resume_model} is not one of #{MODEL_NAMES.join(", ")}"
      end
      # A cursor means nothing without the model it belongs to, and ignoring it
      # would quietly restart the conversion from the first model.
      raise ArgumentError, "a resume id needs a resume model" if resume_id.present? && resume_model.blank?

      @resume_model = resume_model.presence
      @resume_id = resume_id.presence && Integer(resume_id)
      @logger = logger
    end

    def call
      pending_models.each { |model| re_encrypt(model) }
    end

    private

    attr_reader :logger, :resume_model, :resume_id

    def pending_models
      names = resume_model ? MODEL_NAMES.drop(MODEL_NAMES.index(resume_model)) : MODEL_NAMES

      names.map(&:constantize)
    end

    def re_encrypt(model)
      converted = 0
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      scope_for(model).find_in_batches(batch_size: BATCH_SIZE) do |records|
        convert_batch(model, records)
        converted += records.size
        log_progress(model, records.last.id, converted, started_at)
      end

      logger.info("pii:re_encrypt finished #{model.name}: #{converted} rows")
    end

    def scope_for(model)
      return model.all unless model.name == resume_model && resume_id

      model.where(model.primary_key => resume_id..)
    end

    # One transaction per batch. A row that cannot be read stops the run, but the
    # rows before it in the batch are kept, so the cursor it names skips that row
    # alone rather than every unconverted row back to the last logged batch. The
    # failure is raised before that row's UPDATE, so the transaction is still
    # healthy and commits.
    #
    # A duplicate is the exception. Postgres aborts the transaction on it, so the
    # whole batch rolls back and the run resumes from the last logged cursor.
    def convert_batch(model, records)
      unreadable = nil

      model.transaction do
        records.each do |record|
          record.update_columns(plaintext_attributes(record))
        rescue ActiveRecord::Encryption::Errors::Configuration
          # Not a property of the row, so no cursor would get past it.
          raise
        rescue ActiveRecord::Encryption::Errors::Base => e
          unreadable = [record, e]
          break
        rescue ActiveRecord::RecordNotUnique => e
          raise_naming(record, e, "The batch rolled back. Remove the duplicate, then resume from the " \
                                  "last logged cursor")
        end
      end

      return unless unreadable # every row in the batch converted

      record, error = unreadable
      raise_naming(record, error, "Rows before it were saved. To skip it, resume with " \
                                  "pii:re_encrypt[#{model.name},#{record.id + 1}]")
    end

    # Neither bare error says which row it was. The encryption one names
    # deserialize and nothing else, and a duplicate names only ciphertext, which
    # during a maintenance window leaves no way to find the row without bisecting.
    #
    # A duplicate is possible because the unique index on
    # childrens_barred_list_entries covers deterministic ciphertext. Two rows
    # holding the same names and date of birth under different digests pass it,
    # and collide once the second is converted.
    def raise_naming(record, error, next_step)
      raise error.class, "#{record.class.name}##{record.id}: #{error.message.strip}. #{next_step}", error.backtrace
    end

    # Reads every encrypted column to plaintext and writes them all back in one
    # UPDATE, which update_columns serializes under the current digest without
    # running callbacks or touching updated_at. That is what record.encrypt does
    # internally, built by hand here for three reasons.
    #
    # Rails cannot read the seven deterministic columns at all. Rails only
    # attaches a previous scheme to an attribute whose determinism matches, and
    # support_sha1_for_non_deterministic_encryption registers a non-deterministic
    # one, so their plaintext has to be recovered here.
    #
    # The four non-deterministic columns are read here too, rather than through
    # the model. The model's type falls back to returning the raw value when the
    # global support_unencrypted_data is true, so a value readable under neither
    # digest would come back as ciphertext and be encrypted again as plaintext.
    #
    # And the plaintext cannot be assigned to the record first, which is what
    # record.encrypt would need. dfe-analytics wraps write_attribute to track
    # changes, and reads the old value through the model's own type to do it,
    # which raises on the SHA-1 ciphertext being replaced.
    def plaintext_attributes(record)
      ENCRYPTED_ATTRIBUTES.fetch(record.class.name).index_with do |attribute|
        plaintext_for(record, attribute)
      end
    end

    def plaintext_for(record, attribute)
      raw = record.read_attribute_before_type_cast(attribute)
      return raw if raw.nil?

      readers = readers_for(record.class, attribute)
      begin
        readers[:current].deserialize(raw)
      rescue ActiveRecord::Encryption::Errors::Decryption
        readers[:sha1].deserialize(raw)
      end
    end

    # A reader per digest for one column, built once per column for the whole
    # run.
    #
    # Both pin support_unencrypted_data false rather than inheriting it. When that
    # global is true a failed decryption hands back the raw ciphertext instead of
    # raising, so the current reader would appear to succeed and that ciphertext
    # would be encrypted again as though it were plaintext, with verification then
    # reporting the row readable.
    def readers_for(model, attribute)
      deterministic = DETERMINISTIC_ATTRIBUTES.fetch(model.name, []).include?(attribute)

      @readers ||= {}
      @readers[[model.name, attribute]] ||= key_providers(deterministic:).transform_values do |key_provider|
        ActiveRecord::Encryption::EncryptedAttributeType.new(
          scheme: ActiveRecord::Encryption::Scheme.new(
            deterministic:,
            key_provider:,
            support_unencrypted_data: false
          ),
          default: model.columns_hash[attribute.to_s].default
        )
      end
    end

    # The digest in force now, and the one that wrote the rows being converted,
    # for each kind of key. Deriving a key is expensive, so each is built once for
    # the whole run.
    #
    # DeterministicKeyProvider takes no key_generator, so the deterministic SHA-1
    # derivation goes through its parent. For a single key the two are
    # equivalent, and deterministic keys cannot be rotated, so there is only ever
    # one.
    def key_providers(deterministic:)
      @key_providers ||= {}
      @key_providers[deterministic] ||= begin
        config = ActiveRecord::Encryption.config
        key = deterministic ? config.deterministic_key : config.primary_key
        if key.blank?
          raise ActiveRecord::Encryption::Errors::Configuration,
                "no #{deterministic ? "deterministic" : "primary"} encryption key is configured, " \
                "so SHA-1 ciphertext cannot be read"
        end

        current = if deterministic
                    ActiveRecord::Encryption::DeterministicKeyProvider
                  else
                    ActiveRecord::Encryption::DerivedSecretKeyProvider
                  end

        {
          current: current.new(key),
          sha1: ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
            key,
            key_generator: ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
          )
        }
      end
    end

    def log_progress(model, last_id, converted, started_at)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

      logger.info(
        "pii:re_encrypt converted=#{converted} elapsed=#{elapsed.round}s " \
        "rate=#{(converted / [elapsed, 1].max).round}/s " \
        "resume with pii:re_encrypt[#{model.name},#{last_id}]"
      )
    end
  end
end
