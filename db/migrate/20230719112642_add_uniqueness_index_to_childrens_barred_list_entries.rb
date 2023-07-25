class AddUniquenessIndexToChildrensBarredListEntries < ActiveRecord::Migration[
  7.0
]
  def change
    add_index :childrens_barred_list_entries,
              %i[first_names last_name date_of_birth],
              unique: true,
              name: "index_childrens_barred_list_entries_on_names_and_dob"
  end
end
