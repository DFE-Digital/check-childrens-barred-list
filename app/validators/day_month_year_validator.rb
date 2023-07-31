# frozen_string_literal: true

class DayMonthYearValidator
  def validate(record, attribute)
    @record = record

    return true unless all_present?

    record.errors.add(attribute, :invalid) unless valid?
    record.errors.add(attribute, :invalid_year) unless year_valid?
  end

  private

  def all_present?
    @record.day.present? && @record.month.present? && @record.year.present?
  end

  def valid?
    day = @record.day.to_i
    month = @record.month.to_i
    year = @record.year.to_i

    return false unless [day, month, year].all?(&:positive?)

    Date.valid_date?(year, month, day)
  rescue ArgumentError
    false
  end

  def year_valid?
    @record.year.length == 4
  end
end
