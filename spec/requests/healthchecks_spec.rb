require "rails_helper"

RSpec.describe "Healthchecks" do
  describe "/healthcheck" do
    it "responds successfully when the rails server is up" do
      get "/healthcheck"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "/healthcheck/database" do
    it "responds successfully when database is up" do
      get "/healthcheck/database"

      expect(response).to have_http_status(:ok)
    end
  end
end
