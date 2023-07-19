# frozen_string_literal: true

require "rails_helper"

RSpec.describe "No matching record search", type: :system do
  include ActivateFeaturesSteps

  scenario "User searches with no matching last name" do
    given_the_service_is_open
    and_there_is_a_record
    and_i_visit_the_search_page
    and_i_search_for_a_different_last_name
    then_i_see_a_result
  end

  private

  def and_there_is_a_record
    @record = create(:childrens_barred_list_entry)
  end

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_search_for_a_different_last_name
    fill_in "Last name", with: "Random name"
    click_button "Search"
  end

  def then_i_see_a_result
    expect(page).to have_content "No record found"
    expect(page).to have_content "Random name"
  end
end
