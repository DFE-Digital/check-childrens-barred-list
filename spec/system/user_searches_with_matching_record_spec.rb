# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Valid search", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "User searches with a last name", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_there_is_a_record
    and_i_visit_the_search_page
    and_i_enter_their_last_name
    and_i_enter_their_date_of_birth
    and_i_click_search
    then_i_see_a_result
  end

  private

  def and_there_is_a_record
    @record = create(:childrens_barred_list_entry)
  end

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_enter_their_last_name
    fill_in "Last name", with: @record.last_name
  end

  def and_i_enter_their_date_of_birth
    fill_in("Day", with: @record.date_of_birth.day)
    fill_in("Month", with: @record.date_of_birth.month)
    fill_in("Year", with: @record.date_of_birth.year)
  end

  def and_i_click_search
    click_button "Search"
  end

  def then_i_see_a_result
    expect(page).to have_content "Record found"
    expect(page).to have_content @record.last_name
  end
end
