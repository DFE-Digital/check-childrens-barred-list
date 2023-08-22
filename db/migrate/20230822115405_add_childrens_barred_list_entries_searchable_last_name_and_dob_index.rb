class AddChildrensBarredListEntriesSearchableLastNameAndDobIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :childrens_barred_list_entries, %i[searchable_last_name date_of_birth],
      name: "index_cbl_entries_on_searchable_last_name_and_dob"
  end
end
