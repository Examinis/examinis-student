class AddAiFeedbackToUserAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :user_answers, :ai_feedback, :text
  end
end
