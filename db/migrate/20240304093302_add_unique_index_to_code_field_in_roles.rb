class AddUniqueIndexToCodeFieldInRoles < ActiveRecord::Migration[7.1]
  def change
    add_index :roles, 'lower(code)', unique: true, name: 'index_roles_on_lower_code'
  end
end
