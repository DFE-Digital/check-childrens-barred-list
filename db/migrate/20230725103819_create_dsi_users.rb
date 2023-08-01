class CreateDsiUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :dsi_users do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :uid, null: false
      t.timestamps
    end

    add_index :dsi_users, :email, unique: true
  end
end
