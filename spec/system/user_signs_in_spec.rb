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
    within("header") { expect(page).to have_content "Sign out" }
    expect(DsiUser.count).to eq 1
    expect(DsiUserSession.count).to eq 1
  end
end
