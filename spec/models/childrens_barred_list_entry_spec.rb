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
          described_class.includes_record?(
            last_name: record.last_name,
            date_of_birth: record.date_of_birth,
          ),
        ).to be_truthy
      end
    end

    context "with a case-insensitive match on last_name" do
      it "returns true" do
        expect(
          described_class.includes_record?(
            last_name: record.last_name.downcase,
            date_of_birth: record.date_of_birth,
          ),
        ).to be_truthy
      end
    end

    context "with matching DoB but no matching last_name" do
      it "returns false" do
        expect(
          described_class.includes_record?(
            last_name: "Random name",
            date_of_birth: record.date_of_birth,
          ),
        ).to be_falsey
      end
    end

    context "with matching last_name but no matching DoB" do
      it "returns false" do
        expect(
          described_class.includes_record?(
            last_name: record.last_name,
            date_of_birth: Time.zone.today,
          ),
        ).to be_falsey
      end
    end

    context "with no matching DoB or last_name" do
      it "returns false" do
        expect(
          described_class.includes_record?(
            last_name: "Random name",
            date_of_birth: Time.zone.today,
          ),
        ).to be_falsey
      end
    end
  end
end
