class FeedbacksController < ApplicationController
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(feedback_params)

    if @feedback.save
      redirect_to :success
    else
      render :new
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(
      :satisfaction_rating,
      :improvement_suggestion,
      :contact_permission_given,
      :email
    )
  end
end
