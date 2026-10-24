class PublicBookingsController < ApplicationController
  allow_unauthenticated_access
  rescue_from ActiveRecord::RecordNotFound, with: :booking_not_found

  def new
    @user = User.find_by!(slug: params[:slug])
    @event_type = @user.event_types.find_by!(slug: params[:event_type])
    @date = params[:date].present? ? (Date.parse(params[:date]) rescue Date.current) : Date.current
    @slots = SlotFinder.new(@user, @event_type, @date).all_slots
    @booking = @user.bookings.new(event_type: @event_type)
  end

  def create
    @user = User.find_by!(slug: params[:slug])
    @event_type = @user.event_types.find_by!(slug: params[:event_type])

    result = Bookings::Create.new(
      user: @user,
      event_type: @event_type,
      params: booking_params
    ).call

    if result.success?
      redirect_to booking_status_path(result.booking.token), notice: "Rezervasyonunuz başarıyla oluşturuldu."
    else
      flash.now[:alert] = result.error
      @booking = result.booking
      @date = if booking_params[:starts_at].present?
                (Time.zone.parse(booking_params[:starts_at]).to_date rescue Date.current)
              else
                Date.current
              end
      @slots = SlotFinder.new(@user, @event_type, @date).all_slots
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = Booking.find_by!(token: params[:token])

    respond_to do |format|
      format.html
      format.ics do
        send_data IcsGenerator.call(@booking),
                  filename: "randevu_#{@booking.token}.ics",
                  type: "text/calendar"
      end
    end
  end

  def cancel
    @booking = Booking.find_by!(token: params[:token])
    begin
      @booking.cancel!
      redirect_to booking_status_path(@booking.token), notice: "Randevu başarıyla iptal edildi."
    rescue Booking::InvalidTransition => e
      redirect_to booking_status_path(@booking.token), alert: e.message
    end
  end

  def reschedule_form
    @booking = Booking.find_by!(token: params[:token])
    unless @booking.can_reschedule?
      return redirect_to booking_status_path(@booking.token), alert: "Bu randevu için şu an tarih değişikliği yapılamaz."
    end

    @user = @booking.user
    @event_type = @booking.event_type
    @date = params[:date].present? ? (Date.parse(params[:date]) rescue Date.current) : Date.current
    @slots = SlotFinder.new(@user, @event_type, @date).all_slots
  end

  def request_reschedule
    @booking = Booking.find_by!(token: params[:token])
    begin
      @booking.request_reschedule!(
        starts_at: params[:starts_at],
        by: "client",
        note: params[:reschedule_note]
      )
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_requested") rescue nil
      redirect_to booking_status_path(@booking.token), notice: "Tarih değişikliği talebiniz iletildi. Ev sahibi onayladığında randevunuz güncellenecektir."
    rescue Booking::InvalidTransition => e
      redirect_to reschedule_booking_path(@booking.token), alert: e.message
    end
  end

  def accept_reschedule
    @booking = Booking.find_by!(token: params[:token])
    begin
      @booking.accept_reschedule!
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_accepted") rescue nil
      redirect_to booking_status_path(@booking.token), notice: "Yeni randevu saati başarıyla onaylandı ve randevunuz güncellendi."
    rescue Booking::InvalidTransition => e
      redirect_to booking_status_path(@booking.token), alert: e.message
    end
  end

  def reject_reschedule
    @booking = Booking.find_by!(token: params[:token])
    begin
      @booking.reject_reschedule!
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_rejected") rescue nil
      redirect_to booking_status_path(@booking.token), notice: "Tarih değişikliği teklifi reddedildi. Mevcut randevunuz korunuyor."
    rescue Booking::InvalidTransition => e
      redirect_to booking_status_path(@booking.token), alert: e.message
    end
  end

  private

  def booking_params
    params.require(:booking).permit(:invitee_name, :invitee_email, :starts_at, :notes)
  end

  def booking_not_found
    render "public_bookings/not_found", status: :not_found
  end
end
