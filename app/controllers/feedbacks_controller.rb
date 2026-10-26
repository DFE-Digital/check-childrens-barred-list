class FeedbacksController < ApplicationController
  skip_before_action :authenticate_dsi_user!
  skip_before_action :handle_expired_session!

  helper_method :feedback_return_path

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

  # The Back link returns the user to the page they left. A referrer-based
  # link loops back to the form once a submission fails validation, so the
  # origin travels with the request as `return_to` instead.
  def feedback_return_path
    @feedback_return_path ||= build_feedback_return_path
  end

  def build_feedback_return_path
    return_to = url_from(params[:return_to]) # nil for another host, so Back can't link off-site
    return root_path if return_to.blank?

    path = URI(return_to).path # a query string could carry a searched name and date of birth
    return root_path if path.blank? # a bare same-host URL has no path, which would link Back to this form
    return root_path unless returnable?(path)

    path
  end

  def returnable?(path)
    route = Rails.application.routes.recognize_path(path, method: :get)
    return false if route[:controller] == "feedbacks" # Back would reopen the form or its success page
    return false if route.values_at(:controller, :action) == %w[searches show] # /result can't render without its query

    true
  rescue ActionController::RoutingError
    false # no GET page at this path
  end
end
