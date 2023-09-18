class CreateDsiUserSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :dsi_user_sessions do |t|
      t.belongs_to :dsi_user
      t.string :role_id
      t.string :role_code
      t.string :organisation_id
      t.string :organisation_name
      t.timestamps
    end
  end
end
