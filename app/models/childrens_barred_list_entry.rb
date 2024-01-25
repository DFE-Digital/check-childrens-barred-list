class ChildrensBarredListEntry < ApplicationRecord
  encrypts :date_of_birth, :first_names, :last_name, :searchable_last_name, deterministic: true
  encrypts :trn, :national_insurance_number

  REQUIRED_SOURCE_COLUMN_COUNT = 6
  attr_accessor :source_column_count

  validates :first_names, presence: true
  validates :last_name,
            presence: true,
            uniqueness: { scope: %i[first_names date_of_birth] }
  validates :date_of_birth, presence: true
  validates :national_insurance_number,
    format: {
      with: /\A[a-z]{2}[0-9]{6}[a-d]{1}\Z/i
    }, if: -> { national_insurance_number.present? }
  validate :source_column_count_is_correct

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

  def as_json(options = {})
    super(options.merge(methods: %i[failure_messages]))
  end

  def failure_messages
    errors.full_messages
  end

  def source_column_count_is_correct
    return if source_column_count.nil?
    return if source_column_count == REQUIRED_SOURCE_COLUMN_COUNT

    errors.add(:source_column_count, :invalid, required_count: REQUIRED_SOURCE_COLUMN_COUNT)
  end
end
