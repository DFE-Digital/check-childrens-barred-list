# frozen_string_literal: true

require "active_support/parameter_filter"

PG_DETAIL_REGEX = /^DETAIL:.*$/
PG_DETAIL_FILTERED = "[PG DETAIL FILTERED]"

def filter_record_not_unique_exception_messages!(event, hint)
  if hint[:exception].is_a?(ActiveRecord::RecordNotUnique)
    event.exception.values.each do |single_exception| # rubocop:disable Style/HashEachMethods
      single_exception.value.gsub!(PG_DETAIL_REGEX, PG_DETAIL_FILTERED)
    end
  end
end

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]

  config.environment = HostingEnvironment.environment_name

  filter =
    ActiveSupport::ParameterFilter.new(
      Rails.application.config.filter_parameters
    )

  config.before_send = lambda do |event, hint|
    filter_record_not_unique_exception_messages!(event, hint)

    filter.filter(event.to_hash)
  end

  config.inspect_exception_causes_for_exclusion = true
  config.excluded_exceptions += [
    # The following exceptions are user-errors that aren't actionable, and can
    # be safely ignored.
    "ActionController::BadRequest",
    "ActionController::UnknownFormat",
    "ActionController::UnknownHttpMethod",
    "ActionDispatch::Http::Parameters::ParseError",
    "Mime::Type::InvalidMimeType"
  ]
end
