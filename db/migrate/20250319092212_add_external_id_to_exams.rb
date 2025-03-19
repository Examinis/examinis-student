class AddExternalIdToExams < ActiveRecord::Migration[8.0]
  def change
    add_column :exams, :external_id, :integer
    add_index :exams, :external_id
  end
end
