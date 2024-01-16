module DfESignInApi
  class GetOrganisationsForUser
    include Client

    attr_reader :user_id

    def initialize(user_id:)
      @user_id = user_id
    end

    def call
      response = client.get(endpoint)

      if response.success? && response.body.any?
        response.body.reject { |org| org["status"]["name"] == "Closed" }
      else
        []
      end
    end

    private

    def endpoint
      "/users/#{user_id}/organisations"
    end
  end
end
