# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :last_name, :day, :month, :year, :searched_at

  validates :last_name, presence: true

  validate do |search|
    DayMonthYearValidator.new.validate(search, :date_of_birth)
  end

  def date_of_birth
    Date.new(year.to_i, month.to_i, day.to_i)
  rescue StandardError
    InvalidDate.new(day:, month:, year:)
  end

  def day=(value)
    @day = value.delete(" \t\r\n")
  end

  def month=(value)
    @month = value.delete(" \t\r\n")
  end

  def year=(value)
    @year = value.delete(" \t\r\n")
  end
end
