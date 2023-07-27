module AuthorizationSteps
  def when_i_am_authorized_with_basic_auth
    page.driver.basic_authorize(
      ENV.fetch("SUPPORT_USERNAME", "support"),
      ENV.fetch("SUPPORT_PASSWORD", "support")
    )
  end

  def then_i_am_unauthorized
    expect(page.status_code).to eq(401)
  end
end
