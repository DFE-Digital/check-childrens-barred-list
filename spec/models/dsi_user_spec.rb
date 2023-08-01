require "rails_helper"

RSpec.describe DsiUser, type: :model do
  describe ".create_or_update_from_dsi" do
    let(:dsi_payload) do
      OmniAuth::AuthHash.new(uid: "123456", info: { email:, first_name: "John", last_name: "Doe" })
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
  end
end
