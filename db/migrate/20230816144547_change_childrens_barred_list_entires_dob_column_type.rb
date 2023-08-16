class ChangeChildrensBarredListEntiresDobColumnType < ActiveRecord::Migration[7.0]
  def up
    change_column :childrens_barred_list_entries, :date_of_birth, :string
  end

  def down
    change_column :childrens_barred_list_entries, :date_of_birth, :date
  end
end
