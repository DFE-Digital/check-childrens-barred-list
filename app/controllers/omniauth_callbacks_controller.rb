# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  protect_from_forgery except: :dfe_bypass
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  before_action :add_auth_attributes_to_session, only: :dfe

  def dfe
    if DfESignIn.bypass?
      create_or_update_dsi_user
    else
      return redirect_to not_authorised_path unless role
      create_or_update_dsi_user(role)
    end

    redirect_to root_path
  end
  alias_method :dfe_bypass, :dfe

  private

  def auth
    request.env["omniauth.auth"]
  end

  def add_auth_attributes_to_session
    session[:id_token] = auth.credentials.id_token
    session[:organisation_name] = auth.extra.raw_info.organisation.name
  end

  def create_or_update_dsi_user(role = nil)
    @dsi_user = DsiUser.create_or_update_from_dsi(auth, role)
    session[:dsi_user_id] = @dsi_user.id
    session[:dsi_user_session_expiry] = 2.hours.from_now.to_i
  end

  def role
    @role ||= DfESignInApi::GetUserAccessToService.new(
      org_id: auth.extra.raw_info.organisation.id,
      user_id: auth.uid,
    ).call
  end

  def organisations
    @organisations ||= DfESignInApi::GetOrganisationsForUser.new(
      user_id: auth.uid,
    ).call
  end

  def organisation_ids
    organisations&.map { |org| org["id"] }
  end

  def authenticated_organisation_id
    auth.extra.raw_info.organisation.id
  end
end
