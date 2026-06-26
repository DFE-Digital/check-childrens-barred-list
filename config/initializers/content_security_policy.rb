# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
require "dfe_sign_in"

# The sign-in form POSTs to /auth/dfe, which 302-redirects to the DfE Sign-in
# OIDC host; browsers enforce form-action across redirect hops, so 'self' alone
# blocks the OAuth round-trip. Derive the exact issuer origin from the same env
# var OmniAuth uses so the CSP can't drift from the configured provider.
# Bypassed environments use the first-party developer strategy and need it not.
dfe_sign_in_form_action =
  unless DfESignIn.bypass?
    issuer = URI(ENV.fetch("DFE_SIGN_IN_ISSUER", ""))
    "#{issuer.scheme}://#{issuer.host}" if issuer.scheme && issuer.host
  end

Rails.application.configure do
  config.content_security_policy do |policy|
    # Restrict every directive to first-party sources. The :https scheme was
    # removed (ITHC finding) because it allowed resources from any HTTPS host on
    # the internet, which also neutered the script-src nonce. All scripts,
    # styles, fonts and images are bundled locally via esbuild and the asset
    # pipeline, so :self is sufficient.
    policy.default_src     :self
    policy.base_uri        :self
    policy.connect_src     :self
    policy.font_src        :self
    # Allow the derived issuer origin plus the *.education.gov.uk family as a
    # fallback (see the issuer note above).
    policy.form_action     :self, "https://*.education.gov.uk", *Array(dfe_sign_in_form_action)
    policy.frame_ancestors :none
    policy.frame_src       :none
    policy.img_src         :self
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate a fresh random nonce per response for permitted inline scripts.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
