# frozen_string_literal: true
class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  def not_authorised
    render 'not_authorised', status: :unauthorized
  end
end
