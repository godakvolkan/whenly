class AvailabilityRule < ApplicationRecord
  belongs_to :user

  validates :day_of_week, inclusion: { in: 1..7 },
            uniqueness: { scope: :user_id }
  validates :start_time, :end_time, presence: true
  validate :end_after_start

  DAY_NAMES = {
    1 => "Pazartesi",
    2 => "Salı",
    3 => "Çarşamba",
    4 => "Perşembe",
    5 => "Cuma",
    6 => "Cumartesi",
    7 => "Pazar"
  }.freeze

  def day_name
    DAY_NAMES[day_of_week]
  end

  private

  def end_after_start
    return unless start_time && end_time
    # Time comparison for time columns
    t_start = start_time.is_a?(Time) ? start_time.strftime("%H:%M") : start_time.to_s
    t_end   = end_time.is_a?(Time) ? end_time.strftime("%H:%M") : end_time.to_s

    errors.add(:end_time, "başlangıçtan sonra olmalı") if t_end <= t_start
  end
end
