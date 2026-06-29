# This strategy ensures that the id_token_hint param is included in the post_logout_redirect_uri.
# The node-oidc-provider library requires this param to be present in order for the redirect to work.
# We read the token from the session (its single authoritative home, set at the OIDC callback)
# rather than from the request URL, so it is never exposed in a GET request the app generates.
# See: https://github.com/panva/node-oidc-provider/blob/03c9bc513860e68ee7be84f99bfc9dc930b224e8/lib/actions/end_session.js#L27
# See: https://github.com/omniauth/omniauth_openid_connect/blob/34370d655d39fe7980f89f55715888e0ebd7270e/lib/omniauth/strategies/openid_connect.rb#L423
#
module OmniAuth
  module Strategies
    class DfEOpenIDConnect < OmniAuth::Strategies::OpenIDConnect
      TOKEN_KEY = "id_token_hint".freeze

      def encoded_post_logout_redirect_uri
        return unless options.post_logout_redirect_uri

        logout_uri_params = {
          "post_logout_redirect_uri" => options.post_logout_redirect_uri
        }

        # Omit rather than raise when absent so sign-out still works for a session with no token.
        id_token = session["id_token"]
        logout_uri_params[TOKEN_KEY] = id_token if id_token.present?

        URI.encode_www_form(logout_uri_params)
      end
    end
  end
end
