# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "Unauthorised user signs in via DfE Sign In", test: :with_stubbed_auth do
    given_the_service_is_open
    when_i_sign_in_via_dsi(authorised: false)
    then_i_am_not_authorised
  end

  private

  def then_i_am_not_authorised
    expect(page.status_code).to eq 401
  end
end
