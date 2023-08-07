# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invalid search", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps
  include AnalyticsSteps

  scenario "User searches without a last name", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_i_visit_the_search_page
    and_i_click_search
    then_i_see_an_error
    and_event_tracking_is_working
  end

  private

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_click_search
    click_button "Search"
  end

  def then_i_see_an_error
    expect(page).to have_content("Enter a last name")
  end
end
