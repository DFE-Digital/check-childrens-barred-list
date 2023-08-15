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

  it "sets the confirmed field to false" do
    service.call
    expect(ChildrensBarredListEntry.first.confirmed).to eq(false)
  end

  it "sets the upload_file_hash" do
    service.call
    expect(ChildrensBarredListEntry.first.upload_file_hash).to eq(Digest::SHA256.hexdigest(csv_data))
  end
end
