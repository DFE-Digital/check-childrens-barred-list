# frozen_string_literal: true

class TermsAndConditionsController < ApplicationController
  skip_before_action :enforce_terms_and_conditions_acceptance!

  def show
  end

  def update
    current_dsi_user.accept_terms!
    redirect_to root_path, notice: "Terms and conditions accepted"
  end
end
