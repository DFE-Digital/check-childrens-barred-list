module AuthenticationSteps
  def when_i_sign_in_via_dsi(authorised: true)
    given_dsi_auth_is_mocked(authorised:)
    when_i_visit_the_sign_in_page
    and_click_the_dsi_sign_in_button
  end
  alias_method :and_i_am_signed_in_via_dsi, :when_i_sign_in_via_dsi

  def given_dsi_auth_is_mocked(authorised:)
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      {
        provider: "dfe",
        uid: "123456",
        credentials: {
          id_token: "abc123",
        },
        info: {
          email: "test@example.com",
          first_name: "Test",
          last_name: "User"
        },
        extra: {
          raw_info: {
            organisation: {
              id: org_id,
              name: "Test School",
            }
          }
        }
      }
    )

    stub_request(
      :get, user_roles_endpoint
    ).to_return_json(
      status: 200,
      body: { "roles" => [{ "code" => (authorised ? role_code : "Unauthorised_Role") }] },
    )
  end

  def given_dsi_auth_is_mocked_with_a_failure(message)
    allow(Sentry).to receive(:capture_exception)
    OmniAuth.config.mock_auth[:dfe] = message.to_sym
    global_failure_handler = OmniAuth.config.on_failure
    local_failure_handler = proc do |env|
      env["omniauth.error"] = OmniAuth::Strategies::OpenIDConnect::CallbackError.new(error: message)
      env
    end
    OmniAuth.config.on_failure = global_failure_handler << local_failure_handler

    yield if block_given?

    OmniAuth.config.on_failure = global_failure_handler
  end

  def user_roles_endpoint
    "#{ENV.fetch("DFE_SIGN_IN_API_BASE_URL")}/services/checkchildrensbarredlist/organisations/#{org_id}/users/123456"
  end

  def org_id
    "12345678-1234-1234-1234-123456789012"
  end

  def role_code
    ENV.fetch("DFE_SIGN_IN_API_ROLE_CODES").split(",").first
  end

  def when_i_visit_the_sign_in_page
    visit sign_in_path
  end

  def and_click_the_dsi_sign_in_button
    click_button "Sign in"
  end
end
