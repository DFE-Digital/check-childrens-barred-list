class Role < ApplicationRecord
  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: false }

  scope :enabled, -> { where(enabled: true) }
  scope :internal, -> { where(internal: true) }
  scope :external, -> { where(internal: false) }
end
