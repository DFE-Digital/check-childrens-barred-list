require "rails_helper"

RSpec.describe BarredListEntries::UnfindableReport do
  subject(:report) { described_class.new(output:) }

  let(:output) { StringIO.new }
  let(:person) do
    { first_names: "Jane", last_name: "Doe", date_of_birth: "1980-01-01", trn: "1234567",
      national_insurance_number: "AB123456C" }
  end

  describe "#call" do
    it "lists each unfindable entry and counts them" do
      confirmed = create_plaintext_entry(**person)
      before_confirmation = create_plaintext_entry(first_names: "John", last_name: "Smith", confirmed: false)
      before_confirmation.update_columns(upload_file_hash: nil)
      create(:childrens_barred_list_entry, first_names: "Ann", last_name: "Lee")

      aggregate_failures do
        expect(report.call).to eq(entries: 3, entries_holding_plaintext: 2, unreadable_entries: 0,
                                  unfindable_entries: 2, confirmed_unfindable_entries: 1,
                                  unfindable_entries_uploaded_before_confirmation: 1)
        expect(output.string).to include(
          "unfindable entry: #{confirmed.id} (confirmed: true, uploaded before confirmation: false)\n",
          "unfindable entry: #{before_confirmation.id} (confirmed: false, uploaded before confirmation: true)\n"
        )
      end
    end

    it "lists and counts entries it couldn't read" do
      entry = create(:childrens_barred_list_entry, **person)
      store_raw(entry, :date_of_birth, "1980-01-01")
      store_under_unknown_key(entry, :last_name, "Doe")

      aggregate_failures do
        expect(report.call).to include(unreadable_entries: 1, unfindable_entries: 0)
        expect(output.string).to include("unreadable entry: #{entry.id}\n")
      end
    end

    it "prints no value or ciphertext, only counts and ids" do
      create_plaintext_entry(**person)
      create(:childrens_barred_list_entry, first_names: "John", last_name: "Smith", trn: "1111111")

      report.call

      aggregate_failures do
        %w[Jane Doe doe 1980-01-01 1234567 AB123456C John Smith 1111111].each do |value|
          expect(output.string).not_to include(value)
        end
        expect(output.string).not_to include('"p":')
      end
    end

    # search_logs has no index on the name or date, so reading it here would
    # make the quick report slow.
    it "doesn't read search_logs" do
      create_plaintext_entry(**person)

      expect(queries_during { report.call }).not_to include(a_string_matching(/search_logs/))
    end
  end
end
