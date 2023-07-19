class ChildrensBarredListEntry < ApplicationRecord
  validates :first_names, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
end
