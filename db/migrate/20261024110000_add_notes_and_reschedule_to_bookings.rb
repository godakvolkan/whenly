class AddNotesAndRescheduleToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :notes, :text
    add_column :bookings, :reschedule_starts_at, :datetime
    add_column :bookings, :reschedule_ends_at, :datetime
    add_column :bookings, :rescheduled_by, :string
    add_column :bookings, :reschedule_status, :string
    add_column :bookings, :reschedule_note, :text
  end
end
