module AnalyticsSteps
  def and_event_tracking_is_working
    expect(DfE::Analytics::SendEvents).to have_been_enqueued.on_queue("analytics")
                                                            .with([hash_including("event_type" => "web_request")])
                                                            .at_least(1).times
  end
end
