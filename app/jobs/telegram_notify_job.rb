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
    when "reschedule_requested"
      service.notify_host_reschedule_request(booking)
    when "reschedule_accepted"
      service.notify_reschedule_accepted(booking)
    when "reschedule_rejected"
      service.notify_reschedule_rejected(booking)
    end
  end
end
