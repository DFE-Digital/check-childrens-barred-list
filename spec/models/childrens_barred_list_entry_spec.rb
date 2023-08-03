require "rails_helper"

RSpec.describe ChildrensBarredListEntry, type: :model do
  it { is_expected.to validate_presence_of(:first_names) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }

  describe "#self.search" do
    let(:record) { create(:childrens_barred_list_entry) }

    context "with an exact match" do
      it "returns the record" do
        expect(
          described_class.search(
            last_name: record.last_name,
            date_of_birth: record.date_of_birth,
          ),
        ).to eq(record)
      end
    end

    context "with a case-insensitive match on last_name" do
      it "returns the record" do
        expect(
          described_class.search(
            last_name: record.last_name.downcase,
            date_of_birth: record.date_of_birth,
          ),
        ).to eq(record)
      end
    end

    context "with an accent-insensitive match on last_name" do
      it "returns true" do
        expect(
          described_class.search(
            last_name: "Doé",
            date_of_birth: record.date_of_birth,
          ),
        ).to eq(record)
      end
    end

    context "with a whitespace insensitive match on last_name" do
      it "returns true" do
        expect(
          described_class.search(
            last_name: " Doe ",
            date_of_birth: record.date_of_birth,
          ),
        ).to eq(record)
      end
    end

    context "with matching DoB but no matching last_name" do
      it "returns nil" do
        expect(
          described_class.search(
            last_name: "Random name",
            date_of_birth: record.date_of_birth,
          ),
        ).to be_nil
      end
    end

    context "with matching last_name but no matching DoB" do
      it "returns nil" do
        expect(
          described_class.search(
            last_name: record.last_name,
            date_of_birth: Time.zone.today,
          ),
        ).to be_nil
      end
    end

    context "with no matching DoB or last_name" do
      it "returns nil" do
        expect(
          described_class.search(
            last_name: "Random name",
            date_of_birth: Time.zone.today,
          ),
        ).to be_nil
      end
    end
  end
end
