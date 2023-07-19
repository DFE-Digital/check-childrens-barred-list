source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "rails", "~> 7.0.6"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.3"

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

# Provide endpoint for server healthchecks
gem "okcomputer"

# Sentry error reporting
gem "sentry-rails"
gem "sentry-ruby"

# Feature switching
gem "govuk_feature_flags", github: "DFE-Digital/govuk_feature_flags", branch: "main"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
end

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
end

group :test, :development do
  gem "rspec"
  gem "rspec-rails"
end
