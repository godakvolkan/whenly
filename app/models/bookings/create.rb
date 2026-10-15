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

      booking = @user.bookings.new(
        event_type: @event_type,
        invitee_name: @params[:invitee_name],
        invitee_email: @params[:invitee_email],
        starts_at: starts_at,
        ends_at: ends_at
      )

      unless booking.starts_at.present? && SchedulingRules.bookable?(booking.starts_at)
        return Result.new(booking: booking, success?: false, error: "En az 2 saat onceden rezervasyon yapilmali")
      end

      force_pending = SchedulingRules.force_approval?(@user, booking.invitee_email, @event_type)
      booking.status = force_pending ? "pending" : "confirmed"

      if booking.status == "pending"
        booking.approval_deadline_at = SchedulingRules.approval_deadline_for(booking)
      end

      if booking.save
        Result.new(booking: booking, success?: true, error: nil)
      else
        Result.new(booking: booking, success?: false, error: booking.errors.full_messages.join(", "))
      end
    end
  end
end
