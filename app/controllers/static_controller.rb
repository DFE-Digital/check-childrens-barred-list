# frozen_string_literal: true

class StaticController < ApplicationController
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  layout "two_thirds"

  def accessibility
  end

  def cookies
  end
end
