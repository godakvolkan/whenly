class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :event_types, dependent: :destroy
  has_many :availability_rules, dependent: :destroy
  has_many :bookings, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  ROLES = %w[host client].freeze

  validates :role, inclusion: { in: ROLES }

  before_validation :generate_slug, on: :create
  before_create :generate_api_token

  def role
    self[:role].presence || "host"
  end

  def host?
    role == "host"
  end

  def client?
    role == "client"
  end

  def client_bookings
    Booking.where("LOWER(invitee_email) = ?", email_address.downcase).order(starts_at: :desc)
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_slug
    self.slug ||= name&.parameterize.presence || SecureRandom.hex(4)
  end

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
