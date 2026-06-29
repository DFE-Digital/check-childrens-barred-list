# frozen_string_literal: true

require "rails_helper"

RSpec.describe HostingEnvironment do
  describe ".review?" do
    it "is true in the review environment" do
      allow(described_class).to receive(:environment_name).and_return("review")
      expect(described_class.review?).to be true
    end

    it "is false in other environments" do
      allow(described_class).to receive(:environment_name).and_return("production")
      expect(described_class.review?).to be false
    end
  end
end
