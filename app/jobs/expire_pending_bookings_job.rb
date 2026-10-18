class ExpirePendingBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.pending_expired.find_each do |booking|
      booking.expire!
      BookingMailer.booking_expired(booking).deliver_later rescue nil
    end
  end
end
