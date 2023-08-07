class ChildrensBarredListEntry < ApplicationRecord
  validates :first_names, presence: true
  validates :last_name,
            presence: true,
            uniqueness: {
              scope: %i[first_names date_of_birth]
            }
  validates :date_of_birth, presence: true

  def self.search(last_name:, date_of_birth:)
    where(
      "lower(unaccent(last_name)) = ?",
      ActiveSupport::Inflector.transliterate(last_name.strip.downcase)
    ).and(where(date_of_birth:)).first
  end
end
