class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event_type, null: false, foreign_key: true
      t.string :invitee_name, null: false
      t.string :invitee_email, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :approval_deadline_at
      t.string :token, null: false

      t.timestamps
    end
    add_index :bookings, :token, unique: true
    add_index :bookings, [:user_id, :starts_at],
              unique: true,
              where: "status IN ('pending', 'confirmed')",
              name: "idx_bookings_no_double"
  end
end
