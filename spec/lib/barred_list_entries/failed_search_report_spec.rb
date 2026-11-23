require "rails_helper"

RSpec.describe BarredListEntries::FailedSearchReport do
  subject(:report) { described_class.new(output:) }

  let(:output) { StringIO.new }
  let(:user) { create(:dsi_user) }

  def log_search(last_name, result_returned, date_of_birth: "1980-01-01")
    SearchLog.create!(dsi_user: user, last_name:, date_of_birth:, result_returned:)
  end

  describe "#call" do
    # The log holds the last name as typed. A search that found a record, or
    # recorded no result, isn't a failed one.
    it "counts the logged searches for each unfindable entry that returned no record" do
      plaintext = create_plaintext_entry(first_names: "Jane", last_name: "doe", date_of_birth: "1980-01-01")
      [["doe", false], ["DOE", false], ["Doe", false], ["Doe", true], ["Doe", nil], ["Dough", false]]
        .each { |last_name, result_returned| log_search(last_name, result_returned) }
      log_search("doe", false, date_of_birth: "1980-01-02")

      aggregate_failures do
        expect(report.call).to eq 3
        expect(output.string).to include("failed searches for entry #{plaintext.id}: 3\n",
                                          "failed_searches_for_unfindable_entries: 3\n")
      end
    end

    it "skips entries it couldn't read" do
      entry = create(:childrens_barred_list_entry, first_names: "Jane", last_name: "Doe")
      store_raw(entry, :date_of_birth, entry.date_of_birth)
      store_under_unknown_key(entry, :last_name, "Doe")

      aggregate_failures do
        expect(report.call).to eq 0
        expect(output.string).not_to include("entry #{entry.id}")
      end
    end

    it "keeps values out of the output and the SQL text" do
      create_plaintext_entry(first_names: "Jane", last_name: "Doe", date_of_birth: "1980-01-01")
      log_search("Doe", false)

      sql = queries_during { report.call }.join("\n")

      aggregate_failures do
        %w[Jane Doe doe DOE 1980-01-01].each do |value|
          expect(output.string).not_to include(value)
          expect(sql).not_to include(value)
        end
        expect(sql).not_to include('"p":')
      end
    end
  end
end
