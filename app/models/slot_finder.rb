class SlotFinder
  def initialize(user, event_type, date)
    @user = user
    @event_type = event_type
    @date = date.is_a?(String) ? Date.parse(date) : (date || Date.current)
  end

  def available_slots
    rule = @user.availability_rules.find_by(day_of_week: @date.cwday)
    return [] unless rule

    duration = @event_type.duration_minutes.minutes
    slots = []
    current = @date.in_time_zone("Istanbul").change(
      hour: rule.start_time.hour,
      min: rule.start_time.min,
      sec: 0
    )
    day_end = @date.in_time_zone("Istanbul").change(
      hour: rule.end_time.hour,
      min: rule.end_time.min,
      sec: 0
    )

    while current + duration <= day_end
      slot_end = current + duration
      if slot_available?(current, slot_end)
        slots << { starts_at: current, ends_at: slot_end }
      end
      current += duration
    end

    slots
  end

  private

  def slot_available?(starts_at, ends_at)
    return false unless SchedulingRules.bookable?(starts_at)

    !@user.bookings
      .active_or_unexpired_pending
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
      .exists?
  end
end
