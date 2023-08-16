class ChildrensBarredListEntry < ApplicationRecord
  validates :first_names, presence: true
  validates :last_name,
            presence: true,
            uniqueness: {
              scope: %i[first_names date_of_birth]
            }
  validates :date_of_birth, presence: true

  before_save :populate_searchable_last_name

  def self.search(last_name:, date_of_birth:)
    where(
      searchable_last_name: searchable(last_name),
      confirmed: true,
      date_of_birth:,
    ).first
  end

  def populate_searchable_last_name
    self.searchable_last_name = self.class.searchable(last_name)
  end

  def self.searchable(value)
    ActiveSupport::Inflector.transliterate(value.strip.downcase)
  end
end
