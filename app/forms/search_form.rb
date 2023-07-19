# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  attr_accessor :last_name

  validates :last_name, presence: true
end
