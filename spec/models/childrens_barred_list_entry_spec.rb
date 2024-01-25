require "rails_helper"

RSpec.describe ChildrensBarredListEntry, type: :model do
  it { is_expected.to validate_presence_of(:first_names) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }

  describe "validations" do
    it "is valid with a valid national_insurance_number format" do
      entry = build(:childrens_barred_list_entry)
      entry.national_insurance_number = "AB123456D"
      expect(entry).to be_valid
    end

    it "is invalid with an invalid national_insurance_number format" do
      entry = build(:childrens_barred_list_entry)
      entry.national_insurance_number = "AB6D"
      expect(entry).not_to be_valid
      expect(entry.errors.full_messages).to include("National insurance number is invalid")
    end

    describe "source_column_count" do
      let(:params) { attributes_for(:childrens_barred_list_entry) }
      subject { described_class.new(params) }

      context "when not passed" do
        it { is_expected.to be_valid }
      end

      context "when passed" do
        let(:params) { super().merge(source_column_count:) }

        context "when it is REQUIRED_SOURCE_COLUMN_COUNT" do
          let(:source_column_count) { ChildrensBarredListEntry::REQUIRED_SOURCE_COLUMN_COUNT }

          it { is_expected.to be_valid }
        end

        context "when it is not REQUIRED_SOURCE_COLUMN_COUNT" do
          let(:source_column_count) { ChildrensBarredListEntry::REQUIRED_SOURCE_COLUMN_COUNT - 1 }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

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

    context "with an unconfirmed record" do
      let(:record) { create(:childrens_barred_list_entry, :unconfirmed) }
      it "returns nil" do
        expect(
          described_class.search(
            last_name: record.last_name,
            date_of_birth: record.date_of_birth,
          ),
        ).to be_nil
      end
    end
  end

  describe ".before_save" do
    it "populates searchable_last_name" do
      record = build(:childrens_barred_list_entry, last_name: "Doé")
      record.save!
      expect(record.searchable_last_name).to eq("doe")
    end
  end
end
