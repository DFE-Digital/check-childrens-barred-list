class ChildrensBarredListEntry < ApplicationRecord
  validates :first_names, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true

  def self.includes_record?(last_name:)
    where("lower(last_name) = ?", last_name.downcase).any?
  end
end
