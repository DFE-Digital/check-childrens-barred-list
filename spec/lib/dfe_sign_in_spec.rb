# frozen_string_literal: true

require "rails_helper"

RSpec.describe DfESignIn do
  describe ".bypass?" do
    it "is true in a review environment, regardless of BYPASS_DSI" do
      allow(HostingEnvironment).to receive(:review?).and_return(true)
      expect(described_class.bypass?).to be true
    end

    it "is true in a non-review test environment when BYPASS_DSI is set" do
      allow(HostingEnvironment).to receive(:review?).and_return(false)
      allow(HostingEnvironment).to receive(:test_environment?).and_return(true)
      stub_bypass_dsi("true")
      expect(described_class.bypass?).to be true
    end

    it "is false in a non-review test environment without BYPASS_DSI" do
      allow(HostingEnvironment).to receive(:review?).and_return(false)
      allow(HostingEnvironment).to receive(:test_environment?).and_return(true)
      stub_bypass_dsi(nil)
      expect(described_class.bypass?).to be false
    end

    it "is false in a non-test environment" do
      allow(HostingEnvironment).to receive(:review?).and_return(false)
      allow(HostingEnvironment).to receive(:test_environment?).and_return(false)
      expect(described_class.bypass?).to be false
    end
  end

  def stub_bypass_dsi(value)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BYPASS_DSI").and_return(value)
  end
end
