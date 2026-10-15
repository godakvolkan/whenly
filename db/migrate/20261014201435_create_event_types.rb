class CreateEventTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_types do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :duration_minutes, null: false, default: 30
      t.boolean :requires_approval, null: false, default: true
      t.integer :approval_window_hours, default: 24
      t.string :slug, null: false

      t.timestamps
    end
    add_index :event_types, [:user_id, :slug], unique: true
  end
end
