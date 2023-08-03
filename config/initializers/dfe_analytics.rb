require "hosting_environment"

DfE::Analytics.configure do |config|
  # config.async = false
  # config.log_only = true

  config.queue = :analytics
  config.environment = HostingEnvironment.environment_name

  config.enable_analytics =
    proc do
      disabled_by_default = Rails.env.development?
      ENV.fetch("BIGQUERY_DISABLE", disabled_by_default.to_s) != "true"
    end
end
