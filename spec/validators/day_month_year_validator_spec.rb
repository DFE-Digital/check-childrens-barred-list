require "rails_helper"

RSpec.describe DayMonthYearValidator do
  class Validatable
    include ActiveModel::Model
    attr_accessor :day, :month, :year, :date_attribute

    validate do |record|
      DayMonthYearValidator.new.validate(record, :date_attribute)
    end
  end

  subject(:validatable) { Validatable.new(valid_attributes) }

  let(:valid_attributes) { { day: "15", month: "6", year: "1990" } }

  describe "#validate" do
    context "when the date is valid" do
      it "passes validation" do
        validatable.valid?

        expect(validatable).to be_valid
      end
    end

    context "when the date is invalid" do
      it "fails validation with invalid dates" do
        validatable.day = "31"
        validatable.month = "13"
        validatable.valid?

        expect(validatable.errors[:date_attribute]).to include("is invalid")
      end

      it "fails validation with negative dates" do
        validatable.day = -1
        validatable.month = "2"
        validatable.valid?

        expect(validatable.errors[:date_attribute]).to include("is invalid")
      end
    end

    context "when missing fields" do
      it "does not perform validation if day `nil`" do
        validatable.day = nil

        expect(validatable).to be_valid
      end

      it "does not perform validation if month `nil`" do
        validatable.month = nil

        expect(validatable).to be_valid
      end

      it "does not perform validation if year `nil`" do
        validatable.year = nil

        expect(validatable).to be_valid
      end
    end
  end
end
