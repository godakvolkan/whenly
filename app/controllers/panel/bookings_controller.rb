class Panel::BookingsController < Panel::BaseController
  before_action :set_booking, only: [:show, :confirm, :decline, :cancel, :complete, :no_show]

  def index
    redirect_to panel_root_path
  end

  def show
  end

  def confirm
    transition_booking(:confirm!, "Randevu onaylandı.")
  end

  def decline
    transition_booking(:decline!, "Randevu reddedildi.")
  end

  def cancel
    transition_booking(:cancel!, "Randevu iptal edildi.")
  end

  def complete
    transition_booking(:complete!, "Randevu tamamlandı olarak işaretlendi.")
  end

  def no_show
    if SchedulingRules.can_mark_no_show?(@booking)
      transition_booking(:no_show!, "Randevu gelmedi (no-show) olarak işaretlendi.")
    else
      redirect_back fallback_location: panel_root_path, alert: "Toplantı bitişinden en az 15 dakika sonra gelmedi olarak işaretlenebilir."
    end
  end

  private

  def set_booking
    @booking = current_user.bookings.find(params[:id])
  end

  def transition_booking(method_name, success_message)
    @booking.public_send(method_name)
    redirect_back fallback_location: panel_root_path, notice: success_message
  rescue Booking::InvalidTransition => e
    redirect_back fallback_location: panel_root_path, alert: e.message
  end
end
