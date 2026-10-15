class PublicBookingsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.find_by!(slug: params[:slug])
    @event_type = @user.event_types.find_by!(slug: params[:event_type])
    @date = params[:date].present? ? (Date.parse(params[:date]) rescue Date.current) : Date.current
    @slots = SlotFinder.new(@user, @event_type, @date).available_slots
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
      @slots = SlotFinder.new(@user, @event_type, @date).available_slots
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @booking = Booking.find_by!(token: params[:token])
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

  private

  def booking_params
    params.require(:booking).permit(:invitee_name, :invitee_email, :starts_at)
  end
end
