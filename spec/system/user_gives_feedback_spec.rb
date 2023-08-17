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

  private

  def and_i_visit_the_search_page
    visit search_path
  end

  def and_i_click_on_feedback
    click_on "feedback"
  end

  def then_i_see_the_feedback_form
    expect(page).to have_current_path("/feedback")
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
