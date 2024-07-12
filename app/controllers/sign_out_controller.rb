class SignOutController < ApplicationController
  skip_before_action :handle_expired_session!
  skip_before_action :enforce_terms_and_conditions_acceptance!

  before_action :reset_session

  def new
    redirect_to sign_in_path
  end
end
