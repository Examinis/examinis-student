class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.integer :contact_type, null: false, default: 0
      t.string :value, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # Index to optimize queries
    add_index :contacts, :contact_type
  end
end
