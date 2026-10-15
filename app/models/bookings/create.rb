module Bookings
  class Create
    Result = Data.define(:booking, :success?, :error)

    def initialize(user:, event_type:, params:)
      @user = user
      @event_type = event_type
      @params = params
    end

    def call
      starts_at = @params[:starts_at]
      starts_at = Time.zone.parse(starts_at) if starts_at.is_a?(String)

      ends_at = starts_at ? starts_at + @event_type.duration_minutes.minutes : nil

      normalized_email = @params[:invitee_email].to_s.strip.downcase

      booking = @user.bookings.new(
        event_type: @event_type,
        invitee_name: @params[:invitee_name],
        invitee_email: normalized_email,
        starts_at: starts_at,
        ends_at: ends_at
      )

      # 1. En az 2 saat önceden rezervasyon kuralı
      unless booking.starts_at.present? && SchedulingRules.bookable?(booking.starts_at)
        return Result.new(booking: booking, success?: false, error: "En az 2 saat onceden rezervasyon yapilmali")
      end

      # 2. Çalışma saatleri uygunluk kontrolü
      if starts_at.present? && ends_at.present?
        rule = @user.availability_rules.find_by(day_of_week: starts_at.in_time_zone("Istanbul").to_date.cwday)
        if rule.present?
          slot_start_time = starts_at.in_time_zone("Istanbul").strftime("%H:%M:%S")
          slot_end_time = ends_at.in_time_zone("Istanbul").strftime("%H:%M:%S")
          rule_start = rule.start_time.strftime("%H:%M:%S")
          rule_end = rule.end_time.strftime("%H:%M:%S")

          if slot_start_time < rule_start || slot_end_time > rule_end
            return Result.new(
              booking: booking,
              success?: false,
              error: "Seçilen saat çalışma saatleri (#{rule.start_time.strftime('%H:%M')} - #{rule.end_time.strftime('%H:%M')}) dışındadır."
            )
          end
        end
      end

      # 3. Süresi geçmiş pending randevuları otomatik olarak expire et (500 çakışma hatasını engelle)
      @user.bookings.pending_expired.find_each do |expired_booking|
        expired_booking.expire! rescue nil
      end

      # 4. Çakışan aktif randevu kontrolü
      if starts_at.present? && ends_at.present?
        overlapping = @user.bookings.active.where("starts_at < ? AND ends_at > ?", ends_at, starts_at).exists?
        if overlapping
          return Result.new(booking: booking, success?: false, error: "Bu saat diliminde başka bir aktif randevu bulunmaktadır.")
        end
      end

      # 5. Onay zorunluluğu (Normal kural veya Tekrar eden No-Show kuralı)
      force_pending = SchedulingRules.force_approval?(@user, booking.invitee_email, @event_type)
      booking.status = force_pending ? "pending" : "confirmed"

      if booking.status == "pending"
        booking.approval_deadline_at = SchedulingRules.approval_deadline_for(booking)
      end

      begin
        if booking.save
          Result.new(booking: booking, success?: true, error: nil)
        else
          Result.new(booking: booking, success?: false, error: booking.errors.full_messages.join(", "))
        end
      rescue ActiveRecord::RecordNotUnique
        Result.new(booking: booking, success?: false, error: "Bu saat dilimi için zaten bir randevu bulunmaktadır.")
      end
    end
  end
end
