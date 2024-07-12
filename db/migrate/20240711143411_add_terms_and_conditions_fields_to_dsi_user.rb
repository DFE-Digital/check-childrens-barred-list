class AddTermsAndConditionsFieldsToDsiUser < ActiveRecord::Migration[7.1]
  def change
    change_table :dsi_users, bulk: true do |f|
      f.string :terms_and_conditions_version_accepted
      f.datetime :terms_and_conditions_accepted_at
    end
  end
end
