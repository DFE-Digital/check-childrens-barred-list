# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
if Rails.env.production?
  abort("The Rails environment is running in production mode!")
end
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "dfe/analytics/testing"
require "dfe/analytics/rspec/matchers"

require "capybara/cuprite"
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    timeout: 10,
    process_timeout: 30,
    window_size: [1200, 800],
  )
end
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper
  config.fixture_path = Rails.root.join("spec/fixtures")
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.before(:each, type: :system) { driven_by(:cuprite) }
  config.around(:each, test: :with_stubbed_auth) do |example|
    OmniAuth.config.test_mode = true
    example.run
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:dfe)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
