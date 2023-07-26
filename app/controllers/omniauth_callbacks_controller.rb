# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  protect_from_forgery except: :dfe_bypass

  def dfe
    @dsi_user = DsiUser.create_or_update_from_dsi(request.env["omniauth.auth"])
    session[:dsi_user_id] = @dsi_user.id
    session[:dsi_user_session_expiry] = 2.hours.from_now.to_i

    redirect_to root_path
  end
  alias_method :dfe_bypass, :dfe
end
