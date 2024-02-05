require "rails_helper"
require "dfe/analytics/filtered_request_event"

RSpec.describe DfE::Analytics::FilteredRequestEvent do
  describe "#with_request_details" do
    it "filters the request query according to Rails config" do
      allow(Rails.application.config).to receive(:filter_parameters).and_return([:date, :name])

      rack_request = double(
        Rack::Request,
        uuid: "123",
        user_agent: "foo",
        method: "GET",
        path: "/bar",
        query_string: "foo=bar&search[name]=bar]&search[date(3i)]=10&search[date(2i)]=10&search[date(1i)]=2000",
        referer: "http://example.com",
        remote_ip: "1.3.22.21",
      )

      event = described_class.new.with_request_details(rack_request)

      expect(event.as_json).to include(
        "request_uuid" => "123",
        "request_user_agent" => "foo",
        "request_method" => "GET",
        "request_path" => "/bar",
        "request_query" => [
          {"key"=>"foo", "value"=>["bar"]},
          {"key"=>"search[name]", "value"=>["[FILTERED]"]},
          {"key"=>"search[date(3i)]", "value"=>["[FILTERED]"]},
          {"key"=>"search[date(2i)]", "value"=>["[FILTERED]"]},
          {"key"=>"search[date(1i)]", "value"=>["[FILTERED]"]},
        ],
        "request_referer" => "http://example.com",
      )
    end
  end
end
