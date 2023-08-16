module AnalyticsSteps
  def and_event_tracking_is_working
    expect(:web_request).to have_been_enqueued_as_analytics_events
  end
end
