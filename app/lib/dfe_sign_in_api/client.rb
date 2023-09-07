require "jwt"

module DfESignInApi
  module Client
    TIMEOUT_IN_SECONDS = 5

    def client
      @client ||=
        Faraday.new(
          url: ENV.fetch("DFE_SIGN_IN_API_BASE_URL"),
          request: {
            timeout: TIMEOUT_IN_SECONDS
          }
        ) do |faraday|
          faraday.request :authorization, "Bearer", jwt
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
        end
    end

    private

    def jwt
      @jwt ||= JWT.encode(
        {
          iss: ENV.fetch("DFE_SIGN_IN_CLIENT_ID"),
          aud: ENV.fetch("DFE_SIGN_IN_API_AUDIENCE"),
        },
        ENV.fetch("DFE_SIGN_IN_API_SECRET"),
        "HS256",
      )
    end
  end
end
