class RemoveUniqueEmailIndexFromDsiUsers < ActiveRecord::Migration[7.1]
  def change
    remove_index :dsi_users, :email, unique: true, name: "index_dsi_users_on_email"
    add_index :dsi_users, :uid
  end
end
