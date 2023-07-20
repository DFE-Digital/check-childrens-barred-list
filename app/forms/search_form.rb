# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :last_name, :day, :month, :year

  validates :last_name, presence: true
  validates :date_of_birth, presence: true

  validate do |search|
    DayMonthYearValidator.new.validate(search, :date_of_birth)
  end

  def date_of_birth
    Date.new(year.to_i, month.to_i, day.to_i)
  rescue StandardError
    InvalidDate.new(day:, month:, year:)
  end
end
