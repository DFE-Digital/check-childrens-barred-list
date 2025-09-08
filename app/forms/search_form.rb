# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  MONTH_NAMES = {
    "jan" => 1,
    "feb" => 2,
    "mar" => 3,
    "apr" => 4,
    "may" => 5,
    "jun" => 6,
    "jul" => 7,
    "aug" => 8,
    "sep" => 9,
    "oct" => 10,
    "nov" => 11,
    "dec" => 12,
  }.freeze

  attr_accessor :last_name, :searched_at
  # setters are custom to strip whitespace and allow stringified month names
  attr_reader :day, :month, :year

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
    # Support entering month as a name, e.g. "January", "Jan", "january", "jan"
    value = MONTH_NAMES[value.downcase[0, 3]].to_s if value.match?(/\A[a-zA-Z]+\z/)
    @month = value.delete(" \t\r\n")
  end

  def year=(value)
    @year = value.delete(" \t\r\n")
  end
end
