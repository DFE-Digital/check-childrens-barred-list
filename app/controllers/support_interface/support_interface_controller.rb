module SupportInterface
  class SupportInterfaceController < ApplicationController
    before_action :authorize_internal_user!

    def authorize_internal_user!
      render "support_interface/not_authorised", status: :forbidden unless current_dsi_user &&
        current_dsi_user.internal?
    end

    def not_authorised
    end
  end
end

