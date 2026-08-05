require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"
require "ostruct"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CheckTheChildrensBarredList
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "London"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.assets.paths << Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/images")
    config.assets.paths << Rails.root.join("node_modules/govuk-frontend/dist/govuk/assets/fonts")

    config.active_job.queue_adapter = :sidekiq

    # Rails 7.1 defaults derive Active Record encryption keys with SHA-256.
    # Existing production ciphertext was written with SHA-1, and the
    # deterministic columns (email, date_of_birth, last_name, trn,
    # national_insurance_number) back record lookups, so switching the digest
    # would make those lookups miss and non-deterministic values
    # undecryptable. Pinned to SHA-1 until the data is re-encrypted in
    # <FOLLOW-UP TICKET>.
    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA1
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true

    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

    config.exceptions_app = self.routes # rubocop:disable Style/RedundantSelf
  end
end
