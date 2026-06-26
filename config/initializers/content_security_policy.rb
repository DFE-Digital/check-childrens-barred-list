# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
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
    # Allow the DfE Sign-in OIDC host in form-action: the sign-in form POSTs to
    # /auth/dfe which 302-redirects to *.education.gov.uk, and browsers enforce
    # form-action across redirect hops, so 'self' alone blocks the OAuth round-trip.
    policy.form_action     :self, "https://*.education.gov.uk"
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
