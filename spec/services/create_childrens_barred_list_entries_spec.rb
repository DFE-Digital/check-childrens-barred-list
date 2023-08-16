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
    expect(ChildrensBarredListEntry.first.searchable_last_name).to eq("smith")
    expect(ChildrensBarredListEntry.last.first_names).to eq("Jane Jemima")
    expect(ChildrensBarredListEntry.last.last_name).to eq("Jones")
    expect(ChildrensBarredListEntry.last.searchable_last_name).to eq("jones")
  end

  it "sets the confirmed field to false" do
    service.call
    expect(ChildrensBarredListEntry.first.confirmed).to eq(false)
  end

  it "sets the upload_file_hash" do
    expect(service.upload_file_hash).not_to be_nil
    expect(service.upload_file_hash).to eq(Digest::SHA256.hexdigest(csv_data))
  end

  context "when a row is blank" do
    let(:csv_data) do
      [
        [nil, nil, nil, nil, nil].join(",")
      ].join("\n")
    end

    it "does not create a new ChildrensBarredListEntry" do
      expect { service.call }.not_to(change { ChildrensBarredListEntry.count })
    end
  end

  context "when a row has a missing last name field" do
    let(:csv_data) do
      [
        ["12567", nil, "DR. JOHN JAMES ", "01/02/1990", "AB123456C"].join(",")
      ].join("\n")
    end

    it "does not create a new ChildrensBarredListEntry" do
      expect { service.call }.not_to(change { ChildrensBarredListEntry.count })
    end
  end

  context "when a row has a missing first name field" do
    let(:csv_data) do
      [
        ["12567", "SMITH ", nil, "01/02/1990", "AB123456C"].join(",")
      ].join("\n")
    end

    it "does not create a new ChildrensBarredListEntry" do
      expect { service.call }.not_to(change { ChildrensBarredListEntry.count })
    end
  end

  context "when a row contains non-UTF-8 characters" do
    let(:csv_data) do
      [
        ["12567", "Sánchezera-blobbá", "Angélina", "01/11/1990", "AB123456C"].join(","),
      ].join("\n").encode("ISO-8859-1")
    end

    it "encodes as UTF-8" do
      expect { service.call }.to change { ChildrensBarredListEntry.count }.by(1)
      expect(ChildrensBarredListEntry.first.first_names).to eq("Angélina")
      expect(ChildrensBarredListEntry.first.first_names.encoding).to eq(Encoding::UTF_8)
      expect(ChildrensBarredListEntry.first.last_name).to eq("Sánchezera-blobbá")
      expect(ChildrensBarredListEntry.first.last_name.encoding).to eq(Encoding::UTF_8)
    end
  end

  it "compiles a list of failed entries" do
    create(
      :childrens_barred_list_entry,
      first_names: "John James",
      last_name: "Smith",
      date_of_birth: Date.parse("01/02/1990").to_fs(:db),
    )
    service.call
    expect(service.failed_entries.size).to eq(1)
  end
end
