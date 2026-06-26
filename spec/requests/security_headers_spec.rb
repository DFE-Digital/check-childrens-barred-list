require "rails_helper"

RSpec.describe "Security headers", type: :request do
  let(:credentials) do
    ActionController::HttpAuthentication::Basic.encode_credentials(
      ENV.fetch("SUPPORT_USERNAME", "test"),
      ENV.fetch("SUPPORT_PASSWORD", "test"),
    )
  end

  # The Content-Security-Policy is applied by Rails middleware to every
  # response, so the unauthenticated healthcheck endpoint exercises it.
  describe "Content-Security-Policy header" do
    let(:policy) do
      get "/healthcheck"
      response.headers["Content-Security-Policy"]
    end

    it "restricts every directive to first-party sources" do
      expect(policy).to include("default-src 'self'")
      expect(policy).to include("base-uri 'self'")
      expect(policy).to include("connect-src 'self'")
      expect(policy).to include("font-src 'self'")
      expect(policy).to include("frame-ancestors 'none'")
      expect(policy).to include("frame-src 'none'")
      expect(policy).to include("img-src 'self'")
      expect(policy).to include("object-src 'none'")
      expect(policy).to include("style-src 'self'")
    end

    # form-action also allows the DfE Sign-in OIDC host the sign-in form redirects
    # to (browsers enforce form-action across every redirect hop). The exact
    # issuer origin is derived from DFE_SIGN_IN_ISSUER at boot; the
    # *.education.gov.uk family below is the always-present fallback (the derived
    # origin is nil in the test environment, where the issuer is a stub).
    it "allows first-party and the DfE Sign-in domain family in form-action" do
      expect(policy).to include("form-action 'self' https://*.education.gov.uk")
    end

    it "permits nonce-based inline scripts but no external scripts" do
      expect(policy).to match(/script-src 'self' 'nonce-[^']+'/)
    end

    # The ITHC flagged the bare :https scheme source (any HTTPS host) — distinct
    # from an explicit https://host origin, which is fine.
    it "does not allow the bare https: scheme as a source" do
      expect(policy).not_to match(%r{https:(?!//)})
    end

    # Nothing in the compiled assets uses data: URIs, so the permissive
    # scheme is dropped entirely.
    it "does not allow the data: scheme as a source" do
      expect(policy).not_to include("data:")
    end
  end

  # Header-only assertions won't catch a broken nonce in the view, so render a
  # real HTML page (the cookies page skips DfE Sign-in and renders the base
  # layout) and check the nonce is wired through end to end.
  describe "nonce injection in rendered pages" do
    before { get "/cookies", env: { "HTTP_AUTHORIZATION" => credentials } }

    let(:header_nonce) do
      response.headers["Content-Security-Policy"][/script-src 'self' 'nonce-([^']+)'/, 1]
    end
    let(:meta_nonce) { response.body[/<meta name="csp-nonce" content="([^"]+)"/, 1] }
    let(:script_nonce) { response.body[/<script nonce="([^"]+)"/, 1] }

    it "renders successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "injects the nonce into the csp_meta_tag and the inline script tag" do
      expect(meta_nonce).to be_present
      expect(script_nonce).to be_present
    end

    it "uses the same nonce in the meta tag, inline script and CSP header" do
      expect(meta_nonce).to eq(header_nonce)
      expect(script_nonce).to eq(header_nonce)
    end
  end
end
