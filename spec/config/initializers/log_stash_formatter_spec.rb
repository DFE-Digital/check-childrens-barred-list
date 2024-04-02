require "rails_helper"

RSpec.describe LogStashFormatter do
  let(:formatter) { described_class.new }

  let(:info_level_log) do
    {
      application: "AYTQ",
      duration: 253.90900003910065,
      duration_ms: nil,
      environment: "development",
      host: "example-host",
      hosting_environment: "local",
      level: :info,
      level_index: 2,
      message: "Completed #new",
      name: "Users::SessionsController",
      payload: {
        action: "new",
        allocations: 47_495,
        controller: "Users::SessionsController",
        db_runtime: 41.77,
        format: "HTML",
        method: "GET",
        path: "/users/sign_in",
        status: 200,
        status_message: "OK",
        view_runtime: 77.42
      },
      pid: 6092,
      thread: "puma srv tp 002",
      time: "2023-03-30T11:14:00.000+01:00",
      type: "rails"
    }
  end

  let(:fatal_level_log) do
    {
      application: "Semantic Logger",
      duration: nil,
      duration_ms: nil,
      environment: "development",
      exception: {
        name: "ActionController::RoutingError",
        message: "No route matches [GET] \"/users/unknown\"",
        stack_trace: [
          "stack trace line 1",
          "stack trace line 2",
          "stack trace line 3",
          "stack trace line 4",
          "stack trace line 5"
        ]
      },
      host: "example-host",
      hosting_environment: "local",
      level: :fatal,
      level_index: 5,
      line: 93,
      name: "Rails",
      pid: 6092,
      thread: "puma srv tp 004",
      time: "2023-03-23T12:17:42.923+00:00",
      type: "rails"
    }
  end

  before { allow(formatter).to receive(:hash).and_return(log) }

  describe "#format_exception" do
    before { formatter.format_exception }

    context "when there is an info log" do
      let(:log) { info_level_log }

      it "does not change the log" do
        expect(formatter.hash).to eq(log)
      end
    end

    context "when there is an fatal log" do
      let(:log) { fatal_level_log }

      it "adds the error message under the `message` key in the log" do
        expect(formatter.hash[:message]).to eq(
          'Exception occured: No route matches [GET] "/users/unknown"'
        )
      end
    end
  end

  describe "#format_stacktrace" do
    before { formatter.format_stacktrace }

    let(:log) { fatal_level_log }

    it "removes the stacktrace from the exception" do
      expect(formatter.hash[:exception]).to eq(
        {
          name: "ActionController::RoutingError",
          message: "No route matches [GET] \"/users/unknown\""
        }
      )
    end

    it "adds a stacktrace key to the log" do
      expect(formatter.hash[:stacktrace]).to eq(
        ["stack trace line 1", "stack trace line 2", "stack trace line 3"]
      )
    end
  end
end
