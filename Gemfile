source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

gem "rails", "~> 7.2.2"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Build forms and style them using govuk-frontend
gem "govuk-components"
gem "govuk_design_system_formbuilder"

# Convert Markdown into HTML
gem "govuk_markdown"

# Provide endpoint for server healthchecks
gem "okcomputer"

# Sentry error reporting
gem "sentry-rails"
gem "sentry-ruby"

gem "sidekiq", "<7"
gem "sidekiq-cron"

# Feature switching
gem "govuk_feature_flags", github: "DFE-Digital/govuk_feature_flags", branch: "main"

# Authentication
gem "omniauth-oauth2", "~> 1.8"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"

# Sending events to BigQuery
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.14.2"

# Scheduling jobs
gem "clockwork"

# Generate JSON Web Tokens
gem "jwt"

gem 'activerecord-session_store'

group :development do
  gem "prettier_print", require: false
  gem "rladr"
  gem "rubocop-govuk", require: false
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  gem "syntax_tree", require: false
  gem "syntax_tree-haml", require: false
  gem "syntax_tree-rbs", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "shoulda-matchers"
  gem "webmock"
end

group :test, :development do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails"
  gem "launchy"
  gem "pry-byebug"
  gem "rspec"
  gem "rspec-rails"
end

group :development, :test, :review do
  gem "factory_bot_rails"
end

group :development, :production, :review do
  gem "rails_semantic_logger"
end
