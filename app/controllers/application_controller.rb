class ApplicationController < ActionController::Base
  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)

  before_action :http_basic_authenticate, unless: -> { FeatureFlags::FeatureFlag.active?(:service_open) }
  before_action :authenticate_dsi_user!, if: -> { FeatureFlags::FeatureFlag.active?(:service_open) }
  before_action :handle_expired_session!, if: -> { FeatureFlags::FeatureFlag.active?(:service_open) }

  def http_basic_authenticate
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

  def current_dsi_user
    @current_dsi_user ||= DsiUser.find(session[:dsi_user_id]) if session[:dsi_user_id]
  end
  helper_method :current_dsi_user

  def authenticate_dsi_user!
    if current_dsi_user.blank?
      flash[:warning] = "You need to sign in to continue."
      redirect_to sign_in_path
    end
  end

  def dsi_user_signed_in?
    !!current_dsi_user
  end

  def handle_expired_session!
    if session[:dsi_user_session_expiry].nil?
      redirect_to sign_out_path
      return
    end

    if Time.zone.at(session[:dsi_user_session_expiry]).past?
      flash[:warning] = "Your session has expired. Please sign in again."
      redirect_to sign_out_path
    end
  end
end
