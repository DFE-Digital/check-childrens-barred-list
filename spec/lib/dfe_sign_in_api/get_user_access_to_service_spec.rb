require "rails_helper"

RSpec.describe DfESignInApi::GetUserAccessToService do
  describe "#call" do
    let(:org_id) { "123" }
    let(:user_id) { "456" }
    let(:role_id) { "789" }
    let(:standard_role_code) { ENV.fetch("DFE_SIGN_IN_API_ROLE_CODES").split(",").first }
    let(:internal_role_code) { ENV.fetch("DFE_SIGN_IN_API_INTERNAL_USER_ROLE_CODE") }
    let(:endpoint) do
      [
        ENV.fetch("DFE_SIGN_IN_API_BASE_URL"),
        "/services/checkchildrensbarredlist/organisations/#{org_id}/users/#{user_id}"
      ].join
    end

    subject { described_class.new(org_id:, user_id:).call }

    before do
      stub_request(:get, endpoint)
        .to_return_json(
          status: 200,
          body: { "roles" => [{ "id" => role_id, "code" => role_code }] },
        )
    end

    context "when the user is authorised" do
      context "with a standard role code" do
        let(:role_code) { standard_role_code }

        it { is_expected.to eq({ "id" => role_id, "code" => role_code }) }
      end

      context "with an internal role code" do
        let(:role_code) { internal_role_code }

        it { is_expected.to eq({ "id" => role_id, "code" => role_code }) }
      end
    end

    context "when the user is not authorised" do
      let(:role_code) { "Unauthorised_Role" }

      it { is_expected.to be_nil }
    end
  end
end
