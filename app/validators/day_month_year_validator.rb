# frozen_string_literal: true

class DayMonthYearValidator
  attr_accessor :attribute, :record

  def validate(record, attribute)
    self.attribute = attribute
    self.record = record

    validate_date_parts_presence

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

  def validate_date_parts_presence
    if record.day.blank? && record.month.blank?
      record.errors.add(attribute, :missing_day_and_month)
      return
    end

    if record.day.blank? && record.year.blank?
      record.errors.add(attribute, :missing_day_and_year)
      return
    end

    if record.month.blank? && record.year.blank?
      record.errors.add(attribute, :missing_month_and_year)
      return
    end

    if record.day.blank?
      record.errors.add(attribute, :missing_day) 
      return
    end

    if record.month.blank?
      record.errors.add(attribute, :missing_month)
      return
    end

    if record.year.blank?
      record.errors.add(attribute, :missing_year)
    end
  end
end
