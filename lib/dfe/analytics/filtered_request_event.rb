module DfE
  module Analytics
    class FilteredRequestEvent < Event
      def with_request_details(rack_request)
        @event_hash.merge!(
          request_uuid: rack_request.uuid,
          request_user_agent: ensure_utf8(rack_request.user_agent),
          request_method: rack_request.method,
          request_path: ensure_utf8(rack_request.path),
          request_query: hash_to_kv_pairs(
            request_query_filter.filter(Rack::Utils.parse_query(rack_request.query_string))),
          request_referer: ensure_utf8(rack_request.referer),
          anonymised_user_agent_and_ip: anonymised_user_agent_and_ip(rack_request)
        )

        self
      end

      def request_query_filter
        ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      end
    end
  end
end
