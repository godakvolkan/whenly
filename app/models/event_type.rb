class EventType < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :duration_minutes, inclusion: { in: [15, 30, 45, 60] }
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  validates :approval_window_hours, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name&.parameterize
  end
end
