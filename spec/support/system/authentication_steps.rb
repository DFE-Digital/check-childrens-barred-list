module AuthenticationSteps
  def when_i_sign_in_via_dsi(authorised: true, orgs: [organisation], accept_terms_and_conditions: true)
    given_dsi_auth_is_mocked(authorised:, orgs:)
    when_i_visit_the_sign_in_page
    and_wait_for_the_page_to_load
    and_i_accept_the_terms_and_conditions(accept_terms_and_conditions)
  end
  alias_method :and_i_am_signed_in_via_dsi, :when_i_sign_in_via_dsi

  def when_i_sign_in_as_an_internal_user_via_dsi
    given_dsi_auth_is_mocked(authorised: true, internal: true)
    when_i_visit_the_sign_in_page
    and_wait_for_the_page_to_load
    and_i_accept_the_terms_and_conditions(true)
  end
  alias_method :and_i_am_signed_in_as_an_internal_user_via_dsi, :when_i_sign_in_as_an_internal_user_via_dsi

  def given_dsi_auth_is_mocked(authorised: true, internal: false, orgs: [organisation])
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
      :get, organisations_endpoint
    ).to_return_json(
      status: 200,
      body: orgs,
    )

    stub_request(
      :get, user_roles_endpoint
    ).to_return_json(
      status: 200,
      body: { "roles" => roles(authorised:, internal:) },
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

  def roles(authorised: true, internal: false)
    if authorised
      role_codes(internal:).map { |role_code| { "code" => role_code } }
    else
      [{ "code" => "Unauthorised_Role" }]
    end
  end

  def role_codes(internal: false)
    [].tap do |ary|
      ary << create(:role, :enabled).code
      ary << create(:role, :enabled, :internal).code if internal
    end
  end

  def when_i_visit_the_sign_in_page
    visit sign_in_path
  end

  def and_wait_for_the_page_to_load
    page.driver.refresh
  end

  def organisations_endpoint
    "#{ENV.fetch("DFE_SIGN_IN_API_BASE_URL")}/users/123456/organisations"
  end

  def organisation(status: "Open")
    {
      "id" => org_id,
      "name" => "Test School",
      "status" => { "id" => 1, "name" => status },
    }
  end

  def and_i_accept_the_terms_and_conditions(accept)
    if accept
      click_on "Accept"
    end
  end
end
