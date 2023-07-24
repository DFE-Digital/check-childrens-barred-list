# frozen_string_literal: true

class DayMonthYearValidator
  def validate(record, attribute)
    @record = record

    record.errors.add(attribute, :invalid) unless valid?
  end

  private

  def valid?
    unless @record.day.present? && @record.month.present? &&
             @record.year.present?
      return true
    end

    day = @record.day.to_i
    month = @record.month.to_i
    year = @record.year.to_i

    return false unless [day, month, year].all?(&:positive?)

    Date.valid_date?(year, month, day)
  rescue ArgumentError
    false
  end
end
