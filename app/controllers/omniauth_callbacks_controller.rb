# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  protect_from_forgery except: :dfe_bypass
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  def dfe
    auth = request.env["omniauth.auth"]

    unless DfESignIn.bypass?
      role = DfESignInApi::GetUserAccessToService.new(
        org_id: auth.extra.raw_info.organisation.id,
        user_id: auth.uid,
      ).call

      return redirect_to not_authorised_path unless role
    end

    @dsi_user = DsiUser.create_or_update_from_dsi(auth, role)

    session[:dsi_user_id] = @dsi_user.id
    session[:dsi_user_session_expiry] = 2.hours.from_now.to_i

    redirect_to root_path
  end
  alias_method :dfe_bypass, :dfe
end
