require "rails_helper"

RSpec.describe DfESignInApi::GetOrganisationsForUser do
  describe "#call" do
    let(:user_id) { "456" }
    let(:endpoint) do
      [
        ENV.fetch("DFE_SIGN_IN_API_BASE_URL"),
        "/users/#{user_id}/organisations"
      ].join
    end

    let(:open_org) do
      {
        "id" => "org-y",
        "name" => "Organisation Y",
        "status" => { "id" => 1, "name" => "Open" },
      }
    end
    let(:closed_org) do
      {
        "id" => "org-x",
        "name" => "Organisation X",
        "status" => { "id" => 0, "name" => "Closed" },
      }
    end
    let(:body) do
      [open_org, closed_org]
    end

    subject { described_class.new(user_id:).call }

    before do
      stub_request(:get, endpoint)
        .to_return_json(
          status: 200,
          body:,
      )
    end

    context "when the user belongs to an open organisation" do
      it { is_expected.to eq([open_org]) }
    end

    context "when the user only belongs to a closed organisation" do
      let(:body) { [closed_org] }

      it { is_expected.to eq([]) }
    end

    context "when the user doesn't belong to any organisations" do
      let(:body) { [] }

      it { is_expected.to eq([]) }
    end
  end
end
