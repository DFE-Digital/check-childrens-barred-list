class ChildrensBarredListEntry < ApplicationRecord
  validates :first_names, presence: true
  validates :last_name,
            presence: true,
            uniqueness: { scope: %i[first_names date_of_birth] }
  validates :date_of_birth, presence: true
  validates :national_insurance_number,
    format: {
      with: /\A[a-z]{2}[0-9]{6}[a-d]{1}\Z/i
    }, if: -> { national_insurance_number.present? }

  def self.search(last_name:, date_of_birth:)
    where(
      "lower(unaccent(last_name)) = ?",
      ActiveSupport::Inflector.transliterate(last_name.strip.downcase)
    )
    .where(date_of_birth:, confirmed: true)
    .first
  end

  def as_json(options = {})
    super(options.merge(methods: %i[failure_messages]))
  end

  def failure_messages
    errors.full_messages
  end
end
