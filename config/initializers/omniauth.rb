require "dfe_sign_in"

OmniAuth.config.logger = Rails.logger

if DfESignIn.bypass?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :developer,
             fields: %i[uid email first_name last_name],
             uid_field: :uid
  end
else
  dfe_sign_in_issuer_uri = URI(ENV.fetch("DFE_SIGN_IN_ISSUER", "example"))

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect,
             name: :dfe,
             callback_path: "/auth/dfe/callback",
             client_options: {
               host: dfe_sign_in_issuer_uri&.host,
               identifier: ENV["DFE_SIGN_IN_CLIENT_ID"],
               port: dfe_sign_in_issuer_uri&.port,
               redirect_uri: ENV["DFE_SIGN_IN_REDIRECT_URL"],
               scheme: dfe_sign_in_issuer_uri&.scheme,
               secret: ENV.fetch("DFE_SIGN_IN_SECRET", "example")
             },
             discovery: true,
             issuer: "#{dfe_sign_in_issuer_uri}:#{dfe_sign_in_issuer_uri.port}",
             response_type: :code,
             scope: %i[email organisation profile]
  end
end
