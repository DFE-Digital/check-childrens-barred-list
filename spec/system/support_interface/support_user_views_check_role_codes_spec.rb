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
    when_i_add_a_role
    then_the_role_is_added
    when_i_edit_the_role
    then_the_role_is_updated
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

  def when_i_add_a_role
    click_link "Add role"
    fill_in "Code", with: "AnotherCode"
    check "Internal", visible: false
    click_button "Continue"
  end

  def then_the_role_is_added
    expect(page).to have_content "AnotherCode"

    within last_row_of_roles_table do
      expect(page).to have_content "enabled"
      expect(page).to have_content "internal"
    end
  end

  def when_i_edit_the_role
    within last_row_of_roles_table do
      click_link "Edit"
    end

    fill_in "Code", with: "UpdatedCode"
    uncheck "Internal", visible: false
    select "No", from: "Enabled"
    click_button "Continue"
  end

  def then_the_role_is_updated
    expect(page).to have_content "UpdatedCode"
    expect(page).to_not have_content "AnotherCode"

    within last_row_of_roles_table do
      expect(page).to have_content "not enabled"
      expect(page).to have_content "external"
    end
  end

  private

  def last_row_of_roles_table
    all(".govuk-table__row").last
  end
end
