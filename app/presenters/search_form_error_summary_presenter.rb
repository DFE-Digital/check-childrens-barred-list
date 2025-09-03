# frozen_string_literal: true

class SearchFormErrorSummaryPresenter
  YEAR_FIELD = "#search_form_date_of_birth_1i"
  MONTH_FIELD = "#search_form_date_of_birth_2i"
  YEAR_MESSAGES = [
    I18n.t("activemodel.errors.messages.invalid_year"),
    I18n.t("activemodel.errors.messages.missing_year"),
    I18n.t("activemodel.errors.messages.over_100"),
    I18n.t("activemodel.errors.messages.under_16")
  ].freeze
  MONTH_MESSAGES = [
    I18n.t("activemodel.errors.messages.missing_month")
  ].freeze
    
  def initialize(error_messages)
    @error_messages = error_messages
  end

  def formatted_error_messages    
    @error_messages.flat_map do |attribute, messages|
      messages.map do |message|
        if YEAR_MESSAGES.include?(message)
          [attribute, message, YEAR_FIELD]
        elsif MONTH_MESSAGES.include?(message)
          [attribute, message, MONTH_FIELD]
        else
          [attribute, message]
        end
      end
    end
  end
end
