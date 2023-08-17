class AddConfirmationFieldsToChildrensBarredListEntries < ActiveRecord::Migration[7.0]
  def change
    change_table :childrens_barred_list_entries, bulk: true do |t|
      t.boolean :confirmed, default: false, null: false
      t.datetime :confirmed_at
      t.string :upload_file_hash
    end
  end
end
