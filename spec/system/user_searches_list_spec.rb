# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Valid search", type: :system do
  include ActivateFeaturesSteps

  scenario "User searches with a last name" do
    given_the_service_is_open
    and_i_visit_the_search_page
    and_i_search_with_a_last_name
    then_i_see_a_result
  end

  private

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_search_with_a_last_name
    fill_in "Last name", with: "Doe"
    click_button "Search"
  end

  def then_i_see_a_result
    expect(page).to have_content "Doe"
  end
end
