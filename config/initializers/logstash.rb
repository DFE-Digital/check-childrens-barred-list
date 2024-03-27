LogStashLogger.configure do |config|
  config.customize_event do |event|
    event["environment"] = Rails.env
    event["host"] = ENV["HOSTING_DOMAIN"]
    event["hosting_environment"] = ENV["HOSTING_ENVIRONMENT_NAME"]
    event["type"] = "rails"
  end
end
