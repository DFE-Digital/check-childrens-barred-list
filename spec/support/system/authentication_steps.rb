module AuthenticationSteps
  def when_i_sign_in_via_dsi
    given_dsi_auth_is_mocked
    when_i_visit_the_sign_in_page
    and_click_the_dsi_sign_in_button
  end
  alias_method :and_i_am_signed_in_via_dsi, :when_i_sign_in_via_dsi

  def given_dsi_auth_is_mocked
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      {
        provider: "dfe",
        uid: "123456",
        info: {
          email: "test@example.com",
          first_name: "Test",
          last_name: "User"
        }
      }
    )
  end

  def when_i_visit_the_sign_in_page
    visit sign_in_path
  end

  def and_click_the_dsi_sign_in_button
    click_button "Sign in with DSI"
  end
end
