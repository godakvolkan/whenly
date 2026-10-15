class ExpirePendingBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.pending_expired.find_each do |booking|
      booking.expire!
    end
  end
end
