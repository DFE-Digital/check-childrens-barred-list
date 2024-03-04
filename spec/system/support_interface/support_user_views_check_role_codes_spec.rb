# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Viewing Check role codes" do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "Staff user views Check role codes", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_as_an_internal_user_via_dsi
    and_roles_exist
    when_i_navigate_to_the_roles_section
    then_i_can_see_roles
  end

  private

  def and_roles_exist
    FactoryBot.create(:role, code: "TestCode")
  end

  def when_i_navigate_to_the_roles_section
    visit support_interface_root_path
    click_link "Check role codes"
  end

  def then_i_can_see_roles
    expect(page).to have_content "TestCode"
  end
end


