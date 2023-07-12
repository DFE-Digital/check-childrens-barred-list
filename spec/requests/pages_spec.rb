require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /home" do
    it "requires authentication" do
      get "/"
      expect(response).to have_http_status(:unauthorized)
    end

    context "with valid basic auth credentials" do
      let(:credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV.fetch("SUPPORT_USERNAME", "support"),
          ENV.fetch("SUPPORT_PASSWORD", "support")
        )
      end

      it "returns http success" do
        get "/", env: { "HTTP_AUTHORIZATION" => credentials }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
