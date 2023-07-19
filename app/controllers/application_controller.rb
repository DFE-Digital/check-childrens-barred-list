class ApplicationController < ActionController::Base
  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)

  before_action :authenticate, unless: -> { FeatureFlags::FeatureFlag.active?("service_open") }

  def authenticate
    valid_credentials = [
      {
        username: ENV.fetch("SUPPORT_USERNAME", "support"),
        password: ENV.fetch("SUPPORT_PASSWORD", "support")
      }
    ]

    authenticate_or_request_with_http_basic do |username, password|
      valid_credentials.include?({ username:, password: })
    end
  end
end
