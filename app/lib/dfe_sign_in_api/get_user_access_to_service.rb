module DfESignInApi
  class GetUserAccessToService
    include Client

    attr_reader :org_id, :user_id

    def initialize(org_id:, user_id:)
      @org_id = org_id
      @user_id = user_id
    end

    def call
      response = client.get(endpoint)

      if response.success? && response.body.key?("roles")
        response.body["roles"].find { |role| role["code"] == ENV.fetch("DFE_SIGN_IN_API_INTERNAL_USER_ROLE_CODE") } ||
          response.body["roles"].find { |role| authorised_role_codes.include?(role["code"]) }
      end
    end

    private

    def endpoint
      "/services/#{service_id}/organisations/#{org_id}/users/#{user_id}"
    end

    def service_id
      ENV["DFE_SIGN_IN_CLIENT_ID"]
    end

    def authorised_role_codes
      ENV.fetch("DFE_SIGN_IN_API_ROLE_CODES").split(",")
    end
  end
end
