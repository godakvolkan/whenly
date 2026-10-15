class SchedulingRules
  MINIMUM_NOTICE_HOURS = 2
  NO_SHOW_THRESHOLD = 2
  NO_SHOW_MARKING_DELAY_MINUTES = 15

  # Kural 1: En az 2 saat onceden rezervasyon
  def self.bookable?(starts_at)
    return false if starts_at.nil?
    starts_at >= MINIMUM_NOTICE_HOURS.hours.from_now
  end

  # Kural 2: Onay suresi hesaplama
  def self.approval_deadline_for(booking)
    created_at = booking.created_at || Time.current
    approval_hours = booking.event_type&.approval_window_hours || 24
    event_window = created_at + approval_hours.hours
    meeting_cutoff = booking.starts_at - 1.hour
    [event_window, meeting_cutoff].min
  end

  # Kural 3: Gelmeme kontrolu
  def self.repeat_no_show?(user, invitee_email)
    return false if user.nil? || invitee_email.blank?
    Booking.where(user: user, invitee_email: invitee_email, status: "no_show").count >= NO_SHOW_THRESHOLD
  end

  # Kural 3 devami: no_show isaretlenebilir mi?
  def self.can_mark_no_show?(booking)
    booking.status == "confirmed" &&
      Time.current >= booking.ends_at + NO_SHOW_MARKING_DELAY_MINUTES.minutes
  end

  # Kural 3 devami: bu davetli icin onay zorunlu mu?
  def self.force_approval?(user, invitee_email, event_type)
    event_type.requires_approval || repeat_no_show?(user, invitee_email)
  end
end
