# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Feedback", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "User gives feedback", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_i_visit_the_search_page
    and_i_click_on_feedback
    then_i_see_the_feedback_form
    when_i_press_send_feedback
    then_i_see_validation_errors
    and_the_banner_feedback_link_has_no_return_path
    when_i_click_back
    then_i_am_on_the_search_page
    when_i_click_on_feedback
    when_i_press_send_feedback
    then_i_see_validation_errors
    when_i_choose_satisfied
    then_i_see_validation_errors
    when_i_fill_in_how_we_can_improve
    then_i_see_validation_errors
    when_i_choose_yes
    then_i_see_validation_errors
    when_i_enter_an_email
    when_i_press_send_feedback
    then_i_see_the_feedback_sent_page
  end

  scenario "User opens feedback from the feedback sent page", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_i_visit_the_feedback_sent_page
    when_i_click_on_feedback
    then_the_back_link_goes_to_the_service_start
  end

  scenario "User gives feedback from a search result", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_i_am_on_a_search_result_page
    when_i_click_on_feedback
    then_the_feedback_url_does_not_contain_the_search
    and_the_back_link_goes_to_the_service_start
  end

  scenario "User arrives with a return path on another host", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    when_i_visit_the_feedback_page_returning_to_another_host
    then_the_back_link_goes_to_the_service_start
  end

  scenario "User arrives with a return path on this host with no path", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    when_i_visit_the_feedback_page_returning_to_this_host_with_no_path
    then_the_back_link_goes_to_the_service_start
  end

  scenario "User arrives with a return path that isn't a page", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    when_i_visit_the_feedback_page_returning_to_a_missing_page
    then_the_back_link_goes_to_the_service_start
  end

  private

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_visit_the_feedback_sent_page
    visit "/feedback/success"
  end

  def and_i_am_on_a_search_result_page
    @date_of_birth = Date.parse(create(:childrens_barred_list_entry).date_of_birth)
    visit search_path
    fill_in "Last name", with: "Random name"
    fill_in "Day", with: @date_of_birth.day
    fill_in "Month", with: @date_of_birth.month
    fill_in "Year", with: @date_of_birth.year
    click_button "Search"
    expect(page).to have_content("No record found", wait: 10)
  end

  def and_i_click_on_feedback
    click_on "feedback"
  end
  alias_method :when_i_click_on_feedback, :and_i_click_on_feedback

  def when_i_click_back
    click_on "Back"
  end

  def then_i_am_on_the_search_page
    expect(page).to have_current_path(search_path)
  end

  def when_i_visit_the_feedback_page_returning_to_another_host
    visit feedbacks_path(return_to: "https://evil.example/phish")
  end

  def when_i_visit_the_feedback_page_returning_to_this_host_with_no_path
    visit feedbacks_path(return_to: page.server.base_url)
  end

  def when_i_visit_the_feedback_page_returning_to_a_missing_page
    visit feedbacks_path(return_to: "/no-such-page")
  end

  def then_the_feedback_url_does_not_contain_the_search
    aggregate_failures do
      expect(page).to have_current_path("/feedback", ignore_query: true)
      expect(page.current_url).not_to include("search_form")
      expect(page.current_url).not_to include("Random")
      expect(page.current_url).not_to include(@date_of_birth.year.to_s)
    end
  end

  def and_the_banner_feedback_link_has_no_return_path
    expect(page).to have_link("feedback", href: feedbacks_path)
  end

  def then_the_back_link_goes_to_the_service_start
    expect(page).to have_link("Back", href: root_path)
  end
  alias_method :and_the_back_link_goes_to_the_service_start, :then_the_back_link_goes_to_the_service_start

  def then_i_see_the_feedback_form
    expect(page).to have_current_path("/feedback", ignore_query: true)
    expect(page).to have_title("Give feedback about checking the Children’s Barred List")
    expect(page).to have_content("How satisfied are you with the service?")
  end

  def when_i_press_send_feedback
    click_on "Send feedback"
  end

  def then_i_see_validation_errors
    expect(page).to have_content("There’s a problem")
  end

  def when_i_choose_satisfied
    choose "Satisfied", visible: false
  end

  def when_i_fill_in_how_we_can_improve
    fill_in "How can we improve the service?", with: "Make it better"
  end

  def when_i_choose_yes
    choose "Yes", visible: false
  end

  def when_i_enter_an_email
    fill_in "Email address", with: "my_email@example.com"
  end

  def then_i_see_the_feedback_sent_page
    expect(page).to have_current_path("/feedback/success")
    expect(page).to have_title("Feedback sent")
    expect(page).to have_content("What you can do next")
  end
end
