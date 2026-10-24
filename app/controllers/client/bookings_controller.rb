class Client::BookingsController < Client::BaseController
  before_action :set_booking, only: [:show, :cancel, :reschedule, :request_reschedule, :accept_reschedule, :reject_reschedule]

  def index
    all_bookings = current_user.client_bookings.includes(:event_type, :user)

    @pending = all_bookings.select(&:pending?)
    @upcoming = all_bookings.select { |b| b.confirmed? && b.starts_at >= Time.current }
    @past = all_bookings.reject { |b| b.pending? || (b.confirmed? && b.starts_at >= Time.current) }
  end

  def show
  end

  def cancel
    if %w[pending confirmed].include?(@booking.status)
      @booking.cancel!
      redirect_to client_root_path, notice: "Randevunuz başarıyla iptal edildi."
    else
      redirect_to client_root_path, alert: "Bu randevu artık iptal edilemez (mevcut durum: #{@booking.status})."
    end
  rescue Booking::InvalidTransition => e
    redirect_to client_root_path, alert: e.message
  end

  def reschedule
    unless @booking.can_reschedule?
      return redirect_to client_root_path, alert: "Bu randevu için şu an tarih değişikliği yapılamaz."
    end
    @user = @booking.user
    @event_type = @booking.event_type
    @date = params[:date].present? ? (Date.parse(params[:date]) rescue Date.current) : Date.current
    @slots = SlotFinder.new(@user, @event_type, @date).all_slots
  end

  def request_reschedule
    begin
      @booking.request_reschedule!(
        starts_at: params[:starts_at],
        by: "client",
        note: params[:reschedule_note]
      )
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_requested") rescue nil
      redirect_to client_root_path, notice: "Tarih değişikliği talebiniz iletildi. Ev sahibi onayladığında randevunuz güncellenecektir."
    rescue Booking::InvalidTransition => e
      redirect_back fallback_location: client_root_path, alert: e.message
    end
  end

  def accept_reschedule
    begin
      @booking.accept_reschedule!
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_accepted") rescue nil
      redirect_to client_root_path, notice: "Yeni randevu saati başarıyla onaylandı ve randevunuz güncellendi."
    rescue Booking::InvalidTransition => e
      redirect_to client_root_path, alert: e.message
    end
  end

  def reject_reschedule
    begin
      @booking.reject_reschedule!
      TelegramNotifyJob.perform_later(@booking.id, "reschedule_rejected") rescue nil
      redirect_to client_root_path, notice: "Tarih değişikliği teklifi reddedildi. Mevcut randevunuz korunuyor."
    rescue Booking::InvalidTransition => e
      redirect_to client_root_path, alert: e.message
    end
  end

  private

  def set_booking
    @booking = current_user.client_bookings.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    @booking = current_user.client_bookings.find(params[:id])
  end
end
