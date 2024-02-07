module SupportInterface
  class SupportInterfaceController < ApplicationController
    skip_before_action :authenticate_dsi_user!
    before_action :authorize_internal_user!

    def authorize_internal_user!
      render "support_interface/not_authorised", status: :forbidden unless current_dsi_user &&
        current_dsi_user.internal?
    end

    def not_authorised
    end

    private

    def handle_expired_session!
      if session[:dsi_user_session_expiry].nil?
        redirect_to main_app.sign_out_path
        return
      end

      if Time.zone.at(session[:dsi_user_session_expiry]).past?
        flash[:warning] = "Your session has expired. Please sign in again."
        redirect_to main_app.sign_out_path
      end
    end
  end
end

