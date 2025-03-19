class CreateOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :options do |t|
      t.string :description
      t.string :letter
      t.boolean :is_correct
      t.boolean :selected
      t.references :question, null: false, foreign_key: true

      t.timestamps
    end
  end
end
