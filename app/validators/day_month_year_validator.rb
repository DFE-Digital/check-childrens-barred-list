# frozen_string_literal: true

class DayMonthYearValidator
  def validate(record, attribute)
    @record = record

    return true unless all_present?

    unless valid?
      record.errors.add(attribute, :invalid)
      return
    end

    record.errors.add(attribute, :invalid_year) if invalid_year?
    record.errors.add(attribute, :future) if date.future?
    record.errors.add(attribute, :over_100) if over_100?
    record.errors.add(attribute, :under_16) if under_16?
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

  def invalid_year?
    @record.year.length != 4
  end

  def under_16?
    date >= 16.years.ago
  end

  def over_100?
    date <= 100.years.ago
  end

  def date
    @date ||= Date.new(@record.year.to_i, @record.month.to_i, @record.day.to_i)
  end
end
