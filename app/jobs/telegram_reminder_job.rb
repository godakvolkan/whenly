class TelegramReminderJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return unless booking
    return unless booking.confirmed?

    TelegramBotService.new.send_reminder(booking)
  end
end
