# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "User signs out", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    when_i_sign_out
    then_i_am_redirected_to_the_sign_in_page
  end

  private

  def when_i_sign_out
    click_on "Sign out"
  end

  def then_i_am_redirected_to_the_sign_in_page
    expect(page).to have_current_path(ENV.fetch("CHECK_CHILDRENS_BARRED_LIST_GUIDANCE_URL"))
  end
end
