class SignInController < ApplicationController
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!
  skip_before_action :enforce_terms_and_conditions_acceptance!

  before_action :reset_session
  before_action :handle_failed_sign_in, if: -> { params[:oauth_failure] == "true" }

  def new
  end

  private

  def handle_failed_sign_in
    flash.now[:warning] = I18n.t("generic_oauth_failure")
  end
end
