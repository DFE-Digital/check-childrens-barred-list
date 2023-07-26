# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DSI authentication", host: :check_records do
  include AuthorizationSteps
  include CheckRecords::AuthenticationSteps

  scenario "User signs in via DfE Sign In", test: :with_stubbed_auth do
    when_i_am_authorized_with_basic_auth
    when_i_sign_in_via_dsi
    then_i_am_signed_in
  end

  private

  def then_i_am_signed_in
    within("header") { expect(page).to have_content "Sign out" }
    expect(DsiUser.count).to eq 1
  end
end
