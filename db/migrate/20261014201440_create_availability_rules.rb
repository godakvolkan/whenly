class CreateAvailabilityRules < ActiveRecord::Migration[8.1]
  def change
    create_table :availability_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week, null: false # 1=Pzt, 7=Paz
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.timestamps
    end
    add_index :availability_rules, [:user_id, :day_of_week], unique: true
  end
end
