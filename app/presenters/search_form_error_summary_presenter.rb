# frozen_string_literal: true

class SearchFormErrorSummaryPresenter
  YEAR_FIELD = "#search_form_date_of_birth_1i"
  YEAR_MESSAGE = I18n.t("activemodel.errors.models.search_form.attributes.date_of_birth.invalid_year")
    
  def initialize(error_messages)
    @error_messages = error_messages
  end

  def formatted_error_messages    
    @error_messages.map do |attribute, messages|
      message = messages.first
      message == YEAR_MESSAGE ? [attribute, message, YEAR_FIELD] : [attribute, message]
    end
  end
end
