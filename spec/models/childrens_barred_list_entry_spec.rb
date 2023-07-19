require "rails_helper"

RSpec.describe ChildrensBarredListEntry, type: :model do
  it { is_expected.to validate_presence_of(:first_names) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }

  describe "#self.includes_record?" do
    let(:record) { create(:childrens_barred_list_entry) }

    context "with an exact match" do
      it "returns true" do
        expect(
          described_class.includes_record?(last_name: record.last_name),
        ).to be_truthy
      end
    end

    context "with a case-insensitive match" do
      it "returns true" do
        expect(
          described_class.includes_record?(
            last_name: record.last_name.downcase,
          ),
        ).to be_truthy
      end
    end

    context "with no matching record" do
      it "returns false" do
        expect(
          described_class.includes_record?(last_name: "Random name"),
        ).to be_falsey
      end
    end
  end
end
