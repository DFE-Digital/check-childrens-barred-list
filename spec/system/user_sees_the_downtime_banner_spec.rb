# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The downtime banner", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  # Signed-out users go straight from /sign-in to DfE Sign-in without seeing a
  # page of this service, so the search page after sign-in is the first place
  # anyone can see the warning.
  scenario "User sees the planned downtime warning after signing in", test: :with_stubbed_auth do
    given_the_service_is_open
    and_the_downtime_banner_is_active
    and_i_am_signed_in_via_dsi
    when_i_visit_the_search_page
    then_i_see_the_planned_downtime_warning
  end

  scenario "User sees no warning while the banner is off", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    when_i_visit_the_search_page
    then_i_see_no_downtime_warning
  end

  private

  def when_i_visit_the_search_page
    visit search_path
  end

  def then_i_see_the_planned_downtime_warning
    aggregate_failures do
      expect(page).to have_css(".govuk-notification-banner", text: "Important")
      expect(page).to have_content(
        "This service will be unavailable from 9am to 12pm on Wednesday 18 November 2026 " \
        "while we make improvements."
      )
      expect(page).to have_content("You will not be able to use the service during this time.")
    end
  end

  def then_i_see_no_downtime_warning
    # The heading first, so the absence check runs against the loaded page.
    expect(page).to have_css("h1", text: "Check the children’s barred list")
    expect(page).to have_no_css(".govuk-notification-banner")
  end
end
