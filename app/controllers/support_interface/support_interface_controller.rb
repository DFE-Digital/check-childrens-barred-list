module SupportInterface
  class SupportInterfaceController < ApplicationController
    before_action :authorise_internal_user!

    def authorise_internal_user!
    end
  end
end

