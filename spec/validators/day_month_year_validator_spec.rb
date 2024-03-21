require "rails_helper"

class Validatable
  include ActiveModel::Model
  attr_accessor :day, :month, :year, :date_attribute

  validate do |record|
    DayMonthYearValidator.new.validate(record, :date_attribute)
  end
end

RSpec.describe DayMonthYearValidator do
  # We don't have translations for our Validatable test class
  # avoid I18n::MissingTranslationData exceptions by turning off
  # I18n.exception_handler for this particular spec.
  around do |example|
    exception_handler = I18n.exception_handler
    I18n.exception_handler = nil
    example.run
    I18n.exception_handler = exception_handler
  end

  subject(:validatable) { Validatable.new(attributes) }

  describe "#validate" do
    context "when the date is valid" do
      let(:attributes) { { day: "15", month: "6", year: "1990" } }

      it "passes validation" do
        validatable.valid?

        expect(validatable).to be_valid
      end
    end

    context "when the day is invalid" do
      let(:attributes) { { day: "32", month: "6", year: "1990" } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute]).to include("is invalid")
      end
    end

    context "when the month is invalid" do
      let(:attributes) { { day: "15", month: "60", year: "1990" } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute]).to include("is invalid")
      end
    end

    context "when the date is negative" do
      let(:attributes) { { day: -1, month: "6", year: "1990" } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute]).to include("is invalid")
      end
    end

    context "when the year does not have 4 numbers" do
      let(:attributes) { { day: "15", month: "6", year: "90" } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("invalid_year")
      end
    end

    context "when the date is in the future" do
      let(:attributes) { { day: "15", month: "6", year: 1.year.from_now.year.to_s } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("future")
      end
    end

    context "when the date less than 16 years ago" do
      let(:attributes) { { day: "15", month: "6", year: 15.years.ago.year.to_s } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("under_16")
      end
    end

    context "when the date more than 100 years ago" do
      let(:attributes) { { day: "15", month: "6", year: 101.years.ago.year.to_s } }

      it "fails validation" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("over_100")
      end
    end

    context "when day is missing" do
      let(:attributes) { { day: nil, month: "6", year: "1990" } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_day")
      end
    end

    context "when month is missing" do
      let(:attributes) { { day: "15", month: nil, year: "1990" } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_month")
      end
    end

    context "when year is missing" do
      let(:attributes) { { day: "15", month: "6", year: nil } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_year")
      end
    end

    context "when day and month are missing" do
      let(:attributes) { { day: nil, month: nil, year: "1990" } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_day_and_month")
      end
    end

    context "when day and year are missing" do
      let(:attributes) { { day: nil, month: "6", year: nil } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_day_and_year")
      end
    end

    context "when month and year are missing" do
      let(:attributes) { { day: "15", month: nil, year: nil } }

      it "fails validation" do
        expect(validatable).to be_invalid
      end

      it "adds an error message" do
        validatable.valid?

        expect(validatable.errors[:date_attribute].first).to include("missing_month_and_year")
      end
    end
  end
end
