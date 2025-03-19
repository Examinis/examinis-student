class RemoveExamIdFromQuestions < ActiveRecord::Migration[8.0]
  def change
    remove_column :questions, :exam_id, :integer
  end
end
