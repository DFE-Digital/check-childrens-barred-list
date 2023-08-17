require "rails_helper"

RSpec.describe SupportInterface::UploadForm, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:file) }
  end

  describe "#save" do
    it "returns false if the form is invalid" do
      form = described_class.new

      expect(form.save).to eq(false)
    end

    context "when the form is valid" do
      let(:csv_data) do
        [
          ["12567", "Smith", "John James", "01/02/1990", "AB123456C"].join(","),
          ["1234568", "Smith", "Jane Jemima", "07/05/1980", "AB123456D"].join(
            ","
          )
        ].join("\n")
      end

      subject(:form) { described_class.new(file: StringIO.new(csv_data)) }
      let(:save!) { form.save }

      it "creates a new ChildrensBarredListEntry for each row in the CSV" do
        expect { form.save }.to change { ChildrensBarredListEntry.count }.by(2)
      end

      it "populates the upload_file_hash attribute" do
        save!
        expect(ChildrensBarredListEntry.first.upload_file_hash).to eq(Digest::SHA256.hexdigest(csv_data))
        expect(ChildrensBarredListEntry.last.upload_file_hash).to eq(Digest::SHA256.hexdigest(csv_data))
      end
    end

    context "when the file contents are invalid" do
      let(:invalid_csv_data) { %(1, "foo", 3) }

      subject(:form) do
        described_class.new(file: StringIO.new(invalid_csv_data))
      end

      it "adds an error to the file attribute" do
        expect(form.save).to eq(false)
        expect(form.errors[:file]).to include("The selected file must be a CSV")
      end
    end
  end
end
