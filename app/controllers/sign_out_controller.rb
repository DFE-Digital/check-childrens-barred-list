class SignOutController < ApplicationController
  skip_before_action :handle_expired_session!
  before_action :reset_session

  def new
    redirect_to sign_in_path
  end
end
