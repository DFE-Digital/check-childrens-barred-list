require "rails_helper"

RSpec.describe DsiUser, type: :model do
  describe ".create_or_update_from_dsi" do
    let(:dsi_payload) do
      OmniAuth::AuthHash.new(
        uid: "123456",
        info: { email:, first_name: "John", last_name: "Doe" },
        extra: {
          raw_info: {
            organisation: {
              id: "09876",
              name: "Test Org",
            }
          }
        }
      )
    end
    let(:email) { "test@example.com" }

    context "when the user with the email exists" do
      let!(:existing_user) { create(:dsi_user, email:) }

      it "finds the existing user and updates the attributes" do
        result = described_class.create_or_update_from_dsi(dsi_payload)

        expect(result).to eq(existing_user)
        expect(result.uid).to eq dsi_payload.uid
        expect(result.first_name).to eq dsi_payload.info.first_name
        expect(result.last_name).to eq dsi_payload.info.last_name
      end
    end

    context "when the user with the email does not exist" do
      it "creates a new user" do
        expect { described_class.create_or_update_from_dsi(dsi_payload) }.to change {
          DsiUser.count
        }.from(0).to(1)
        dsi_user = DsiUser.first

        expect(dsi_user.uid).to eq dsi_payload.uid
        expect(dsi_user.first_name).to eq dsi_payload.info.first_name
        expect(dsi_user.last_name).to eq dsi_payload.info.last_name
      end
    end

    context "when the user has a role" do
      it "creates a session record" do
        role = { "id" => "123", "code" => "TestRole_code" }
        described_class.create_or_update_from_dsi(dsi_payload, role)

        dsi_user_session = DsiUser.first.dsi_user_sessions.first
        expect(dsi_user_session).to be_present
        expect(dsi_user_session.role_id).to eq "123"
        expect(dsi_user_session.role_code).to eq "TestRole_code"
        expect(dsi_user_session.organisation_id).to eq "09876"
        expect(dsi_user_session.organisation_name).to eq "Test Org"
      end
    end
  end

  describe "#current_session" do
    let(:dsi_user) { create(:dsi_user) }
    let!(:expected_current_session) { create(:dsi_user_session, dsi_user:, created_at: 1.second.ago) }
    let!(:dsi_user_sessions) do
      [10.minutes.ago, 1.minute.ago].each do |created_at|
        create(:dsi_user_session,dsi_user:, created_at:)
      end
    end

    it "returns the latest session" do
      expect(dsi_user.current_session).to eq expected_current_session
    end
  end

  describe "#internal?" do
    let(:dsi_user) { create(:dsi_user) }

    context "when the user has the internal role in their current session" do
      let!(:dsi_user_session) do
        create(:dsi_user_session, dsi_user:, role_code: create(:role, :enabled, :internal).code)
      end

      it "returns true" do
        expect(dsi_user.internal?).to eq true
      end
    end

    context "when the user does not have the internal role in their current session" do
      let!(:dsi_user_session) do
        create(:dsi_user_session, dsi_user:, role_code: "random role")
      end

      it "returns false" do
        expect(dsi_user.internal?).to eq false
      end
    end
  end
end
