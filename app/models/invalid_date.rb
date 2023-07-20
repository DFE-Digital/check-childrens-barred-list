# frozen_string_literal: true

# The InvalidDate class is an ActiveModel model used for situations when
# the date provided is not valid. This date is passed to the view so it is
# rendered as a normal date via the attribues: `day`, `month` and `year`.
#
class InvalidDate
  include ActiveModel::Model

  attr_accessor :day, :month, :year

  def blank?
    [day, month, year].any?(&:blank?)
  end

  def present?
    false
  end
end
