require "rails_helper"

RSpec.describe CreateChildrensBarredListEntries do
  let(:csv_data) do
    [
      ["12567", "SMITH ", "DR. JOHN JAMES ", "01/02/1990", "AB123456C"].join(","),
      ["1234568", " jones ", " mrs jane jemima", "07/05/1980", "AB123456D"].join(",")
    ].join("\n")
  end

  subject(:service) { described_class.new(csv_data) }

  it "creates a new ChildrensBarredListEntry for each row in the CSV" do
    expect { service.call }.to change { ChildrensBarredListEntry.count }.by(2)
  end

  it "updates existing matching entries" do
    existing_entry = ChildrensBarredListEntry.create!(
      last_name: "Jones",
      first_names: "Jane Jemima",
      date_of_birth: "07/05/1980"
    )
    service.call
    expect(existing_entry.reload.trn).to eq("1234568")
    expect(existing_entry.national_insurance_number ).to eq("AB123456D")
  end

  it "zero pads the TRN" do
    service.call
    expect(ChildrensBarredListEntry.first.trn).to eq("0012567")
  end

  it "formats the names" do
    service.call
    expect(ChildrensBarredListEntry.first.first_names).to eq("John James")
    expect(ChildrensBarredListEntry.first.last_name).to eq("Smith")
    expect(ChildrensBarredListEntry.last.first_names).to eq("Jane Jemima")
    expect(ChildrensBarredListEntry.last.last_name).to eq("Jones")
  end
end
