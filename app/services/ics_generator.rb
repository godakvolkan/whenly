class IcsGenerator
  def self.call(booking)
    new(booking).generate
  end

  def initialize(booking)
    @booking = booking
  end

  def generate
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Whenly//Booking//TR
      CALSCALE:GREGORIAN
      METHOD:PUBLISH
      BEGIN:VEVENT
      DTSTART:#{format_time(@booking.starts_at)}
      DTEND:#{format_time(@booking.ends_at)}
      SUMMARY:#{@booking.event_type.name} - #{@booking.invitee_name}
      DESCRIPTION:#{description}
      LOCATION:#{@booking.event_type.location}
      STATUS:CONFIRMED
      UID:#{@booking.token}@whenly
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  def to_file
    file = Tempfile.new(["booking_#{@booking.token}", ".ics"])
    file.write(generate)
    file.rewind
    file
  end

  private

  def format_time(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def description
    parts = []
    parts << "Ev Sahibi: #{@booking.user.name}"
    parts << "Tur: #{@booking.event_type.name}"
    parts << "Sure: #{@booking.event_type.duration_minutes} dk"
    parts << "Konum: #{@booking.event_type.location}" if @booking.event_type.location.present?
    parts.join("\\n")
  end
end
