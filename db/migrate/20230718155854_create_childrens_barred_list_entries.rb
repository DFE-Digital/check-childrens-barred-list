class CreateChildrensBarredListEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :childrens_barred_list_entries do |t|
      t.string :trn
      t.string :first_names, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :national_insurance_number

      t.timestamps
    end
  end
end
