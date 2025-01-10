class SignOutController < ApplicationController
  skip_before_action :handle_expired_session!
  skip_before_action :enforce_terms_and_conditions_acceptance!

  before_action :reset_session

  def new
    redirect_to ENV.fetch("CHECK_RECORDS_GUIDANCE_URL", "https://www.gov.uk/guidance/check-the-childrens-barred-list"),
                allow_other_host: true
  end
end
