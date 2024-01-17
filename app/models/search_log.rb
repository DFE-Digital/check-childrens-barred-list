class SearchLog < ApplicationRecord
  encrypts :date_of_birth, :last_name, deterministic: true
  belongs_to :dsi_user
end
