class ChangeSearchLogsDobColumnTypeToString < ActiveRecord::Migration[7.1]
  def up
    change_column :search_logs, :date_of_birth, :string
  end

  def down
    change_column :search_logs, :date_of_birth, :date
  end
end
