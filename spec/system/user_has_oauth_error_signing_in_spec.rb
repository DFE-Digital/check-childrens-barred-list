# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  before do
    given_the_service_is_open
    allow(Sentry).to receive(:capture_exception)
  end

  scenario "User has oauth error when signing in", test: :with_stubbed_auth do
    given_dsi_auth_is_mocked_with_a_failure("invalid_credentials") do
      when_i_visit_the_sign_in_page
      and_click_the_dsi_sign_in_button
      then_i_see_a_sign_in_error
    end
  end

  scenario "User has sessionexpiry oauth error", test: :with_stubbed_auth do
    given_dsi_auth_is_mocked_with_a_failure("sessionexpired") do
      when_i_visit_the_sign_in_page
      and_click_the_dsi_sign_in_button
      then_i_am_redirected_to_sign_in
    end
  end

  private

  def then_i_see_a_sign_in_error
    expect(page).to have_content "There was a problem signing you in. Please try again."
  end

  def then_i_am_redirected_to_sign_in
    expect(page).to have_current_path(sign_in_path)
  end
end
