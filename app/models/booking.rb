class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :event_type

  after_commit :broadcast_update

  STATUSES = %w[pending confirmed declined canceled completed no_show expired].freeze

  TRANSITIONS = {
    "confirm"  => { from: "pending",   to: "confirmed" },
    "decline"  => { from: "pending",   to: "declined" },
    "expire"   => { from: "pending",   to: "expired" },
    "complete" => { from: "confirmed", to: "completed" },
    "no_show"  => { from: "confirmed", to: "no_show" }
  }.freeze

  validates :status, inclusion: { in: STATUSES }
  validates :invitee_name, :invitee_email, :starts_at, :ends_at, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :normalize_email
  before_validation :set_token, on: :create

  class InvalidTransition < StandardError; end

  TRANSITIONS.each do |action, rule|
    define_method(:"#{action}!") do
      raise InvalidTransition, "#{status} -> #{rule[:to]} izin verilmiyor" unless status == rule[:from]
      update!(status: rule[:to])
    end
  end

  # Özel durum: confirm! süresi dolmuş randevularda izin verilmez
  def confirm!
    raise InvalidTransition, "#{status} -> confirmed izin verilmiyor" unless status == "pending"
    if approval_deadline_at.present? && Time.current >= approval_deadline_at
      expire!
      raise InvalidTransition, "Randevunun onay süresi dolduğu için onaylanamaz."
    end
    update!(status: "confirmed")
  end

  # Özel durum: cancel! hem 'pending' hem 'confirmed' durumundan gecilebilir
  def cancel!
    raise InvalidTransition, "#{status} -> canceled izin verilmiyor" unless %w[pending confirmed].include?(status)
    update!(status: "canceled")
  end

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  scope :active, -> { where(status: %w[pending confirmed]) }
  scope :pending_expired, -> {
    where(status: "pending")
      .where("approval_deadline_at <= ?", Time.current)
  }
  scope :active_or_unexpired_pending, -> {
    where(status: "confirmed")
      .or(where(status: "pending").where("approval_deadline_at > ?", Time.current))
  }
  scope :reschedule_pending, -> { where(reschedule_status: "pending") }

  def reschedule_pending?
    reschedule_status == "pending"
  end

  def can_reschedule?
    %w[pending confirmed].include?(status) && !reschedule_pending?
  end

  def request_reschedule!(starts_at:, by:, note: nil)
    raise InvalidTransition, "Bu randevu için tarih değişikliği yapılamaz (Durum: #{status})" unless can_reschedule?

    starts_at = Time.zone.parse(starts_at) if starts_at.is_a?(String)
    raise InvalidTransition, "Geçersiz randevu tarihi" unless starts_at.present?

    unless SchedulingRules.bookable?(starts_at)
      raise InvalidTransition, "Yeni tarih en az 2 saat sonrasına olmalıdır."
    end

    new_ends_at = starts_at + event_type.duration_minutes.minutes

    rule = user.availability_rules.find_by(day_of_week: starts_at.in_time_zone("Istanbul").to_date.cwday)
    if rule.present?
      slot_start_time = starts_at.in_time_zone("Istanbul").strftime("%H:%M:%S")
      slot_end_time = new_ends_at.in_time_zone("Istanbul").strftime("%H:%M:%S")
      rule_start = rule.start_time.strftime("%H:%M:%S")
      rule_end = rule.end_time.strftime("%H:%M:%S")

      if slot_start_time < rule_start || slot_end_time > rule_end
        raise InvalidTransition, "Seçilen saat ev sahibinin çalışma saatleri (#{rule.start_time.strftime('%H:%M')} - #{rule.end_time.strftime('%H:%M')}) dışındadır."
      end
    end

    conflict = user.bookings.active.where.not(id: id).where("starts_at < ? AND ends_at > ?", new_ends_at, starts_at).exists?
    if conflict
      raise InvalidTransition, "Seçtiğiniz yeni tarih/saatte başka bir randevu bulunmaktadır."
    end

    update!(
      reschedule_starts_at: starts_at,
      reschedule_ends_at: new_ends_at,
      rescheduled_by: by.to_s,
      reschedule_status: "pending",
      reschedule_note: note
    )
  end

  def accept_reschedule!
    raise InvalidTransition, "Bekleyen bir tarih değişikliği talebi bulunmuyor" unless reschedule_pending?

    conflict = user.bookings.active.where.not(id: id).where("starts_at < ? AND ends_at > ?", reschedule_ends_at, reschedule_starts_at).exists?
    if conflict
      raise InvalidTransition, "Talep edilen yeni saat dilimi artık müsait değil."
    end

    update!(
      starts_at: reschedule_starts_at,
      ends_at: reschedule_ends_at,
      status: "confirmed",
      reschedule_status: "accepted"
    )
  end

  def reject_reschedule!
    raise InvalidTransition, "Bekleyen bir tarih değişikliği talebi bulunmuyor" unless reschedule_pending?

    update!(reschedule_status: "rejected")
  end

  private

  def normalize_email
    self.invitee_email = invitee_email.to_s.strip.downcase if invitee_email.present?
  end

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end

  def broadcast_update
    BookingsChannel.broadcast_to(user, {
      type: "booking_update",
      booking_id: id,
      status: status,
      invitee_name: invitee_name
    })
  end
end
