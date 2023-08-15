require "rails_helper"

RSpec.describe "Upload file", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "Support user uploads a valid CSV file", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_via_dsi
    and_i_am_on_the_upload_page
    when_i_upload_a_valid_csv_file
    then_i_see_a_preview_of_the_data
    when_i_confirm_the_upload
    then_i_see_a_success_message
  end

  def given_the_service_is_open
    FeatureFlags::FeatureFlag.activate(:service_open)
  end

  def and_i_am_on_the_upload_page
    visit new_support_interface_upload_path
  end

  def when_i_upload_a_valid_csv_file
    attach_file "support_interface_upload_form[file]",
                Rails.root.join("spec/fixtures/example.csv")
    click_on "Upload file"
  end

  def then_i_see_a_preview_of_the_data
    expect(page).to have_content("Review and confirm")
    within("table thead") do
      expect(page).to have_content("Last name")
      expect(page).to have_content("First names")
      expect(page).to have_content("Date of birth")
      expect(page).to have_content("TRN")
      expect(page).to have_content("NIN")
    end

    within("table tbody") do
      expect(page).to have_content("Simpson")
      expect(page).to have_content("Homer Duff")

      expect(page).to have_content("Banner")
      expect(page).to have_content("Bruce Angry")
    end
  end

  def when_i_confirm_the_upload
    click_on "Confirm"
  end

  def then_i_see_a_success_message
    expect(page).to have_content("Records uploaded")
  end
end
