class TelegramNotifyJob < ApplicationJob
  queue_as :default

  def perform(booking_id, event_type)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    service = TelegramBotService.new

    case event_type
    when "new_booking"
      service.notify_host_new_booking(booking)
    when "confirmed"
      service.notify_invitee_status(booking, "✅ Onaylandı")
    when "declined"
      service.notify_invitee_status(booking, "❌ Reddedildi")
    end
  end
end
