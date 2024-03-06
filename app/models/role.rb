class Role < ApplicationRecord
  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: false }
end
