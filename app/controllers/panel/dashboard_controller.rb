class Panel::DashboardController < Panel::BaseController
  def index
    expire_overdue_bookings
    @pending = current_user.bookings.where(status: "pending").order(starts_at: :asc)
    @upcoming = current_user.bookings.where(status: "confirmed").where("starts_at > ?", Time.current).order(starts_at: :asc)
    @past = current_user.bookings.where(status: %w[completed no_show canceled declined expired]).order(starts_at: :desc).limit(20)
  end

  private

  def expire_overdue_bookings
    current_user.bookings.pending_expired.find_each(&:expire!)
  end
end
