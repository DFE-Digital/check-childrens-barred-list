require "rails_helper"

RSpec.describe "Upload file", type: :system do
  include ActivateFeaturesSteps
  include AuthenticationSteps

  scenario "Support user uploads a valid CSV file", test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_as_an_internal_user_via_dsi
    and_entries_exist_in_the_database
    and_i_am_on_the_upload_page
    when_i_upload_a_valid_csv_file
    then_i_see_a_preview_of_what_will_be_saved
    and_i_can_see_what_will_not_be_saved
    when_i_cancel_the_upload
    then_i_am_redirected_to_the_upload_page
    and_unconfirmed_entries_are_removed
    when_i_upload_a_valid_csv_file
    when_i_confirm_the_upload
    then_i_see_a_success_message
  end

  scenario "Support user uploads an CSV file that contains rows with an incorrect number of columns",
test: :with_stubbed_auth do
    given_the_service_is_open
    and_i_am_signed_in_as_an_internal_user_via_dsi
    and_i_am_on_the_upload_page
    when_i_upload_a_csv_file_with_an_incorrect_number_of_columns
    then_i_see_failed_entries
  end

  def given_the_service_is_open
    FeatureFlags::FeatureFlag.activate(:service_open)
  end

  def and_i_am_on_the_upload_page
    visit new_support_interface_upload_path
  end

  alias_method :then_i_am_redirected_to_the_upload_page, :and_i_am_on_the_upload_page

  def and_entries_exist_in_the_database
    create(
      :childrens_barred_list_entry,
      last_name: "Simpson",
      first_names: "Homer Duff",
      date_of_birth: "1980-01-19",
    )
  end

  def when_i_upload_a_valid_csv_file
    attach_file "support_interface_upload_form[file]",
                Rails.root.join("spec/fixtures/example.csv")
    click_on "Upload file"
  end

  def then_i_see_a_preview_of_what_will_be_saved
    expect(page).to have_content("Review and confirm")
    within(valid_entries_table) do
      within("thead") do
        expect(page).to have_content("Last name")
        expect(page).to have_content("First names")
        expect(page).to have_content("Date of birth")
        expect(page).to have_content("TRN")
        expect(page).to have_content("NIN")
      end

      within("tbody") do
        expect(page).to have_content("Banner")
        expect(page).to have_content("Bruce Angry")
      end
    end
  end

  def when_i_cancel_the_upload
    click_on "Cancel"
  end

  def and_unconfirmed_entries_are_removed
    expect(ChildrensBarredListEntry.where(confirmed: false).count).to eq(0)
  end

  def and_i_can_see_what_will_not_be_saved
    expect(page).to have_content("1 entry will not be saved")

    within(invalid_entries_table) do
      expect(page).to have_content("Simpson")
      expect(page).to have_content("Homer Duff")
      expect(page).to have_content("1980-01-19")
      expect(page).to have_content("Last name with same first names and date of birth already exists")
    end
  end

  def when_i_confirm_the_upload
    click_on "Confirm"
  end

  def then_i_see_a_success_message
    expect(page).to have_content("Records uploaded")
  end

  def when_i_upload_a_csv_file_with_an_incorrect_number_of_columns
    attach_file "support_interface_upload_form[file]",
                Rails.root.join("spec/fixtures/example-incorrect-columns.csv")
    click_on "Upload file"
  end

  def then_i_see_failed_entries
    expect(page).to have_content("4 entries will not be saved")

    within(invalid_entries_table) do
      expect(page).to have_content("Darby")
      expect(page).to have_content("James")
      expect(page).to have_content("10/11/1979")
      expect(page).to have_content("The uploaded file must have 6 columns")
    end
  end

  def valid_entries_table
    page.all("table")[1]
  end

  def invalid_entries_table
    page.all("table")[0]
  end

end
