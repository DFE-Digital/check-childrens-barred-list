class LogStashFormatter < SemanticLogger::Formatters::Raw
  def call(log, logger)
    super(log, logger)

    format_exception
    format_stacktrace

    hash.to_json
  end

  def format_exception
    exception_message = hash.dig(:exception, :message)
    return if exception_message.blank?

    hash[:message] = "Exception occured: #{exception_message}"
  end

  def format_stacktrace
    stack_trace = hash.dig(:exception, :stack_trace)
    return if stack_trace.blank?

    hash[:stacktrace] = stack_trace.first(3)
    hash[:exception].delete(:stack_trace)
  end
end

if ENV["LOGSTASH_HOST"] && ENV["LOGSTASH_PORT"]
  warn("logstash configured, sending logs there")

  # For some reason logstash / elasticsearch drops events where the payload
  # is a hash. These are more conveniently accessed at the top level of the
  # event, anyway, so we move it there.
  customize_event = ->(event) do
    if event["payload"].present?
      event.append(event["payload"])
      event["payload"] = nil
    end
  end

  logger =
    LogStashLogger.new(
      {
        host: ENV["LOGSTASH_HOST"],
        port: ENV["LOGSTASH_PORT"],
        ssl_enable: true,
        type: :tcp
      }.merge(customize_event:)
    )
  SemanticLogger.add_appender(logger:, level: :info, formatter: LogStashFormatter.new)
end
