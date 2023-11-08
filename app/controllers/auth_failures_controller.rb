class AuthFailuresController < ApplicationController
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  class OpenIdConnectProtocolError < StandardError; end

  def failure
    return redirect_to(dsi_sign_out_path(id_token_hint: session[:id_token])) if session_expired?
    handle_failure_then_redirect_to sign_in_path(oauth_failure: true)
  end

  private

  def handle_failure_then_redirect_to(path)
    oidc_error = OpenIdConnectProtocolError.new(error_message)
    unless Rails.env.development?
      Sentry.capture_exception(oidc_error)
      redirect_to(path) and return
    end

    raise oidc_error
  end

  def error_message
    @error_message ||= request.env["omniauth.error"]&.message
  end

  def session_expired?
    error_message == "sessionexpired"
  end
end
