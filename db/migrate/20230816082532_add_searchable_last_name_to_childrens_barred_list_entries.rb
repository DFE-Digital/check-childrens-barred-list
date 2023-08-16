class AddSearchableLastNameToChildrensBarredListEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :childrens_barred_list_entries, :searchable_last_name, :string
  end
end
