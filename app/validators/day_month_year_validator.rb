# frozen_string_literal: true

class DayMonthYearValidator
  attr_accessor :attribute, :record

  def validate(record, attribute)
    self.attribute = attribute
    self.record = record

    return unless validate_date_parts_presence # return here as we already know the entered date is invalid
    return unless validate_parseable_date # return here as further checks rely on a parseable date
    return unless validate_four_figure_year # return here as further checks would just be duplicate errors
    return unless validate_not_future # return here as further checks would just be duplicate errors

    validate_under_100
    validate_over_16
  end

  private

  def all_present?
    @record.day.present? && @record.month.present? && @record.year.present?
  end

  def parseable_date?
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
    # Perform each check individually so we can add specific error messages and return false if any are invalid
    [validate_day_presence, validate_month_presence, validate_year_presence].all?
  end

  def validate_day_presence
    return true if record.day.present?

    record.errors.add(attribute, :missing_day)
    false
  end

  def validate_month_presence
    return true if record.month.present?

    record.errors.add(attribute, :missing_month)
    false
  end

  def validate_year_presence
    return true if record.year.present?

    record.errors.add(attribute, :missing_year)
    false
  end

  def validate_parseable_date
    return true if parseable_date?

    record.errors.add(attribute, :invalid)
    false
  end

  def validate_four_figure_year
    return true unless invalid_year?

    record.errors.add(attribute, :invalid_year)
    false
  end

  def validate_sensible_year
    validate_four_figure_year && validate_not_future
  end

  def validate_not_future
    return true unless date.future?

    record.errors.add(attribute, :future)
    false
  end


  def validate_under_100
    return true unless over_100?

    record.errors.add(attribute, :over_100)
    false
  end

  def validate_over_16
    return true unless under_16?

    record.errors.add(attribute, :under_16)
    false
  end
end
