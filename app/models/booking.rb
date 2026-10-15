class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :event_type

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

  private

  def normalize_email
    self.invitee_email = invitee_email.to_s.strip.downcase if invitee_email.present?
  end

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
