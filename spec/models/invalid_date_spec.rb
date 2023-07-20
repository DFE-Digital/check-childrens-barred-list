# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvalidDate do
  subject(:date) { described_class.new(day: "27", month: "4", year: "1990") }

  describe "#blank?" do
    it "returns false when all fields are present" do
      expect(date).not_to be_blank
    end

    it "returns true when all fields are blank" do
      date.day = ""
      date.month = ""
      date.year = ""

      expect(date).to be_blank
    end

    it "returns false when month is blank" do
      date.month = ""

      expect(date).to be_blank
    end

    it "returns false when day is blank" do
      date.day = ""

      expect(date).to be_blank
    end

    it "returns false when year is blank" do
      date.year = ""

      expect(date).to be_blank
    end
  end

  describe "#present?" do
    it "returns false" do
      expect(date).not_to be_present
    end
  end
end
