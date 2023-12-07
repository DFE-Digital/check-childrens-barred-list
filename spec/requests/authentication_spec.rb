require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "GET /" do
    it "requires authentication" do
      get "/"
      expect(response).to have_http_status(:unauthorized)
    end

    context "with valid basic auth credentials" do
      let(:credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV.fetch("SUPPORT_USERNAME", "support"),
          ENV.fetch("SUPPORT_PASSWORD", "support"),
        )
      end

      it "redirects to sign-in" do
        get "/", env: { "HTTP_AUTHORIZATION" => credentials }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/sign-in")
      end
    end
  end
end
