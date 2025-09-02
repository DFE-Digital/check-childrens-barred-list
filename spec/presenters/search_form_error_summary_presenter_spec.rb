require "rails_helper"

RSpec.describe SearchFormErrorSummaryPresenter do
  describe "#formatted_error_messages" do
    subject(:presenter) { described_class.new({ date_of_birth: [message] }) }

    describe "#formatted_error_messages" do
      context "when the error relates to a non-year field" do
        let(:message) { "Other error" }
  
        it "does not add a custom link" do
          expect(presenter.formatted_error_messages).to eq([[:date_of_birth, message]])
        end
      end
  
      context "when the error relates to the year field" do
        let(:message) { I18n.t("activemodel.errors.messages.invalid_year") }
  
        it "adds a custom link" do
          expect(presenter.formatted_error_messages).to eq([[:date_of_birth, message, "#search_form_date_of_birth_1i"]])
        end
      end
    end
  end
end
