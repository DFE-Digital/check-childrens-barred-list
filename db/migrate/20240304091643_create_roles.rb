class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :code, null: false
      t.boolean :enabled, null: false, default: false
      t.boolean :internal, null: false, default: false

      t.timestamps
    end
  end
end
