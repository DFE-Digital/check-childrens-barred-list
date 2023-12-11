# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "User signs in via DfE Sign In", test: :with_stubbed_auth do
    given_the_service_is_open
    when_i_sign_in_via_dsi
    then_i_am_signed_in
    and_i_cannot_access_the_support_interface
  end

  scenario "Internal user signs in via DfE Sign In", test: :with_stubbed_auth do
    given_the_service_is_open
    when_i_sign_in_as_an_internal_user_via_dsi
    then_i_am_signed_in
    and_i_can_access_the_support_interface
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

  def and_i_can_access_the_support_interface
    visit support_interface_root_path
    expect(page).to have_content("Features")
    click_on "File upload"
    expect(page).to have_content("Upload records")
  end

  def and_i_cannot_access_the_support_interface
    not_authorised_message = "You cannot use the DfE Sign-in account for Test School to perform this action"
    visit root_path
    expect(page).not_to have_content("Features")
    visit support_interface_root_path
    expect(page).to have_content(not_authorised_message)
    visit new_support_interface_upload_path
    expect(page).to have_content(not_authorised_message)
  end
end
