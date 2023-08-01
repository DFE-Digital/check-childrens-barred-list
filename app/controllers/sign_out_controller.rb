class SignOutController < ApplicationController
  skip_before_action :handle_expired_session!

  def new
    session[:dsi_user_id] = nil if dsi_user_signed_in?
  end
end
