class Panel::DashboardController < Panel::BaseController
  def index
    expire_overdue_bookings
    @pending = current_user.bookings.where(status: "pending").order(starts_at: :asc)
    @upcoming = current_user.bookings.where(status: "confirmed").where("ends_at >= ?", Time.current).order(starts_at: :asc)
    @past = current_user.bookings.where(status: %w[completed no_show canceled declined expired])
                         .or(current_user.bookings.where(status: "confirmed").where("ends_at < ?", Time.current))
                         .order(starts_at: :desc).limit(20)
    load_stats
  end

  private

  def expire_overdue_bookings
    current_user.bookings.pending_expired.find_each(&:expire!)
  end

  def load_stats
    all_bookings = current_user.bookings
    @total_count = all_bookings.count
    @confirmed_count = all_bookings.where(status: "confirmed").count
    @pending_count = all_bookings.where(status: "pending").count
    @no_show_count = all_bookings.where(status: "no_show").count
    @completed_count = all_bookings.where(status: "completed").count
    @declined_count = all_bookings.where(status: "declined").count
    @canceled_count = all_bookings.where(status: "canceled").count
    @expired_count = all_bookings.where(status: "expired").count

    decided_total = @confirmed_count + @completed_count + @declined_count + @canceled_count + @expired_count + @no_show_count
    @approval_rate = decided_total > 0 ? (((@confirmed_count + @completed_count).to_f / decided_total) * 100).round(1) : 0

    attended_pool = @confirmed_count + @completed_count + @no_show_count
    @no_show_rate = attended_pool > 0 ? ((@no_show_count.to_f / attended_pool) * 100).round(1) : 0

    @reschedule_pending_count = all_bookings.where(reschedule_status: "pending").count

    @status_data = {
      "Onaylı" => @confirmed_count,
      "Bekleyen" => @pending_count,
      "Tamamlanan" => @completed_count,
      "No-Show" => @no_show_count,
      "Reddedilen" => @declined_count,
      "İptal" => @canceled_count,
      "Süresi Dolmuş" => @expired_count
    }

    day_names = %w[Paz Pzt Sal Çar Per Cum Cmt]

    # Haftalık grafik verisi (Son 7 Gün)
    @weekly_data = {}
    6.downto(0).each do |days_ago|
      date = Date.current - days_ago.days
      count = all_bookings.where("DATE(starts_at) = ?", date).count
      label = "#{date.strftime('%d/%m')} #{day_names[date.wday]}"
      @weekly_data[label] = count
    end

    @daily_data = all_bookings
      .where("starts_at >= ?", 30.days.ago)
      .group("DATE(starts_at)")
      .count
      .transform_keys { |k| k.strftime("%d/%m") }

    @busiest_day_data = all_bookings
      .group("EXTRACT(DOW FROM starts_at)")
      .count
      .transform_keys { |k| day_names[k.to_i] }

    @busiest_hour_data = all_bookings
      .group("EXTRACT(HOUR FROM starts_at)")
      .count
      .transform_keys { |k| "#{k.to_i.to_s.rjust(2, '0')}:00" }
      .sort_by { |k, _| k }
      .to_h
  end
end
