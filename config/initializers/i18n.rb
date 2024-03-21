module I18n
  class SentryExceptionHandler
    def call(exception, _locale, _key, _options)
      if Rails.env.production? && exception.is_a?(MissingTranslation)
        Sentry.capture_exception(exception)
      else
        raise exception.respond_to?(:to_exception) ? exception.to_exception : exception
      end
    end
  end
end

I18n.exception_handler = I18n::SentryExceptionHandler.new
