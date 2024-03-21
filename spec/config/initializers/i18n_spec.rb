require "rails_helper"

RSpec.describe I18n::SentryExceptionHandler do
  let(:key) { "missing.translation" }

  describe "#call" do
    it "raises exceptions in non-production environments" do
      expect { I18n.translate(key) }.to raise_exception(I18n::MissingTranslationData)
    end
    context "in production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Sentry).to receive(:capture_exception)
      end
      it "captures the exception in Sentry" do
        I18n.translate(key)
        expect(Sentry).to have_received(:capture_exception).with(
          I18n::MissingTranslation.new(:en, key)
        )
      end
    end
  end
end
