class BookingMailer < ApplicationMailer
  default from: -> { ENV.fetch("SMTP_FROM", ENV.fetch("SMTP_USERNAME", "bayulgen5546@gmail.com")) }

  # Davetliye: Randevu talebiniz alındı, ev sahibi onayı bekleniyor
  def pending_approval(booking)
    @booking = booking
    @user = booking.user
    @event_type = booking.event_type
    @status_url = booking_status_url(booking.token, host: app_host)

    mail(
      to: @booking.invitee_email,
      subject: "Randevu Talebiniz Alındı — Ev Sahibi Onayı Bekleniyor (#{@event_type.name})"
    )
  end

  # Ev sahibine: Yeni bir randevu talebi onayınızı bekliyor
  def new_booking_request(booking)
    @booking = booking
    @user = booking.user
    @event_type = booking.event_type
    @dashboard_url = panel_root_url(host: app_host)

    mail(
      to: @user.email_address,
      subject: "Yeni Randevu Talebi: #{@booking.invitee_name} (#{@event_type.name})"
    )
  end

  # Davetliye: Randevunuz ev sahibi tarafından ONAYLANDI
  def booking_confirmed(booking)
    @booking = booking
    @user = booking.user
    @event_type = booking.event_type
    @status_url = booking_status_url(booking.token, host: app_host)

    mail(
      to: @booking.invitee_email,
      subject: "Randevunuz Onaylandı! — #{@event_type.name} (#{@user.name})"
    )
  end

  # Davetliye: Randevunuz reddedildi
  def booking_declined(booking)
    @booking = booking
    @user = booking.user
    @event_type = booking.event_type

    mail(
      to: @booking.invitee_email,
      subject: "Randevu Talebiniz Hakkında — #{@event_type.name}"
    )
  end

  # Davetliye: Süresi dolan talep
  def booking_expired(booking)
    @booking = booking
    @user = booking.user
    @event_type = booking.event_type

    mail(
      to: @booking.invitee_email,
      subject: "Randevu Talebinizin Süresi Doldu — #{@event_type.name}"
    )
  end

  private

  def app_host
    ENV.fetch("APP_HOST", "localhost:3000")
  end
end
