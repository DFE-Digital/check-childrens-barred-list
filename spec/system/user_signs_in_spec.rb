# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "User signs in via DfE Sign In", test: :with_stubbed_auth do
    given_the_service_is_open
    when_i_sign_in_via_dsi
    then_i_am_signed_in
  end

  private

  def then_i_am_signed_in
    within("header") do
      expect(page).to have_link("Sign out")
      sign_out_link = find_link("Sign out")
      # Expect the token from mocked auth to be in the sign out link
      expect(sign_out_link[:href]).to include "id_token_hint=abc123"
    end
    expect(DsiUser.count).to eq 1
    expect(DsiUserSession.count).to eq 1
  end
end
